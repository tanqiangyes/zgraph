// Copyright 2022 zGraph Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package executor

import (
	"context"
	"math"

	"github.com/pingcap/errors"
	"github.com/vescale/zgraph/catalog"
	"github.com/vescale/zgraph/codec"
	"github.com/vescale/zgraph/expression"
	"github.com/vescale/zgraph/parser/ast"
	"github.com/vescale/zgraph/parser/model"
	"github.com/vescale/zgraph/planner"
	"github.com/vescale/zgraph/storage/kv"
	"github.com/vescale/zgraph/types"
	"golang.org/x/exp/slices"
)

type MatchExec struct {
	baseExecutor

	subgraph *planner.Subgraph

	prepared bool
	matched  map[string]*types.GraphVar
	results  []expression.Row
	txn      kv.Transaction
}

func (m *MatchExec) Next(ctx context.Context) (expression.Row, error) {
	if !m.prepared {
		if err := m.prepare(ctx); err != nil {
			return nil, err
		}
		m.prepared = true
	}
	if len(m.results) == 0 {
		return nil, nil
	}
	row := m.results[0]
	m.results = m.results[1:]
	return row, nil
}

func (m *MatchExec) prepare(ctx context.Context) error {
	m.matched = make(map[string]*types.GraphVar)

	txn, err := m.sc.Store().Begin()
	if err != nil {
		return err
	}
	m.txn = txn

	return m.search(ctx)
}

// search performs a depth-first search on the graph.
func (m *MatchExec) search(ctx context.Context) error {
	// Enumerate all possible connections to vertices that have not been visited.
	for _, conn := range m.subgraph.Connections {
		edge, ok := conn.(*planner.Edge)
		if !ok {
			return errors.Errorf("variable-length path is not supported yet")
		}
		if _, ok := m.matched[edge.Name().L]; ok {
			continue
		}
		_, srcVisited := m.matched[edge.SrcVarName().L]
		_, dstVisited := m.matched[edge.DstVarName().L]
		if !srcVisited && !dstVisited {
			continue
		}

		if srcVisited && dstVisited {
			edgeVar, err := m.matchEdge(ctx, edge, m.matched[edge.SrcVarName().L].ID, m.matched[edge.DstVarName().L].ID)
			if err != nil {
				return err
			}
			if edgeVar == nil {
				return nil
			}
			return m.stepEdge(ctx, edge, edgeVar)
		}

		if !dstVisited {
			srcID := m.matched[edge.SrcVarName().L].ID
			dstVertex := m.subgraph.Vertices[edge.DstVarName().L]
			return m.iterEdge(ctx, edge, srcID, dstVertex, ast.EdgeDirectionOutgoing, func(edgeVar, endVar *types.GraphVar) error {
				m.matched[edge.DstVarName().L] = endVar
				defer func() {
					delete(m.matched, edge.DstVarName().L)
				}()
				return m.stepEdge(ctx, edge, edgeVar)
			})
		}

		if !srcVisited {
			dstID := m.matched[edge.DstVarName().L].ID
			srcVertex := m.subgraph.Vertices[edge.SrcVarName().L]
			return m.iterEdge(ctx, edge, dstID, srcVertex, ast.EdgeDirectionIncoming, func(edgeVar, endVar *types.GraphVar) error {
				m.matched[edge.SrcVarName().L] = endVar
				defer func() {
					delete(m.matched, edge.SrcVarName().L)
				}()
				return m.stepEdge(ctx, edge, edgeVar)
			})
		}
	}

	// The subgraph is disconnected, so we need to find a new start vertex.
	for _, vertex := range m.subgraph.Vertices {
		_, visited := m.matched[vertex.Name.L]
		if visited {
			continue
		}
		return m.iterVertex(vertex, func(vertexVar *types.GraphVar) error {
			return m.stepVertex(ctx, vertex, vertexVar)
		})
	}

	return nil
}

func (m *MatchExec) stepVertex(ctx context.Context, vertex *planner.Vertex, vertexVar *types.GraphVar) error {
	m.matched[vertex.Name.L] = vertexVar
	defer func() {
		delete(m.matched, vertex.Name.L)
	}()
	if m.isMatched() {
		m.appendResult()
		return nil
	}
	return m.search(ctx)
}

func (m *MatchExec) stepEdge(ctx context.Context, edge *planner.Edge, edgeVar *types.GraphVar) error {
	m.matched[edge.Name().L] = edgeVar
	defer func() {
		delete(m.matched, edge.Name().L)
	}()
	if m.isMatched() {
		m.appendResult()
		return nil
	}
	return m.search(ctx)
}

func (m *MatchExec) isMatched() bool {
	return len(m.matched) == len(m.subgraph.Vertices)+len(m.subgraph.Connections)
}

func (m *MatchExec) appendResult() {
	result := make(expression.Row, 0, len(m.subgraph.SingletonVars))
	for _, singletonVar := range m.subgraph.SingletonVars {
		var d types.Datum
		d.SetGraphVar(m.matched[singletonVar.Name.L])
		result = append(result, d)
	}
	m.results = append(m.results, result)
}

func (m *MatchExec) iterVertex(vertex *planner.Vertex, f func(vertexVar *types.GraphVar) error) error {
	graph := m.sc.CurrentGraph()
	lower := codec.VertexKey(graph.Meta().ID, 0)
	upper := codec.VertexKey(graph.Meta().ID, math.MaxInt64)
	iter, err := m.txn.Iter(lower, upper)
	if err != nil {

		return err
	}
	defer iter.Close()

	for ; err == nil && iter.Valid(); err = iter.Next() {
		// TODO: better way to skip edge keys
		if len(iter.Key()) != codec.VertexKeyLen {
			continue
		}
		_, vertexID, err := codec.ParseVertexKey(iter.Key())
		if err != nil {
			return err
		}

		vertexVar, err := m.decodeGraphVar(iter.Value())
		if err != nil {
			return err
		}
		vertexVar.ID = vertexID
		if !matchLabels(vertexVar.Labels, vertex.Labels) {
			continue
		}

		// Check if the vertex matches the label requirements.
		if len(vertex.Labels) > 0 {
			if !slices.ContainsFunc(vertexVar.Labels, func(labelName string) bool {
				return slices.ContainsFunc(vertex.Labels, func(label *catalog.Label) bool {
					return label.Meta().Name.L == labelName
				})
			}) {
				continue
			}
		}
		if err := f(vertexVar); err != nil {
			return err
		}
	}
	return nil
}

func (m *MatchExec) iterEdge(
	ctx context.Context,
	edge *planner.Edge,
	startID int64,
	endVertex *planner.Vertex,
	direction ast.EdgeDirection,
	f func(edgeVar, endVar *types.GraphVar) error,
) error {
	graph := m.sc.CurrentGraph()
	var lower, upper []byte
	if direction == ast.EdgeDirectionOutgoing {
		lower = codec.OutgoingEdgeKey(graph.Meta().ID, startID, 0)
		upper = codec.OutgoingEdgeKey(graph.Meta().ID, startID, math.MaxInt64)
	} else {
		lower = codec.IncomingEdgeKey(graph.Meta().ID, 0, startID)
		upper = codec.IncomingEdgeKey(graph.Meta().ID, math.MaxInt64, startID)
	}
	iter, err := m.txn.Iter(lower, upper)
	if err != nil {
		return err
	}
	defer iter.Close()

	for ; err == nil && iter.Valid(); err = iter.Next() {
		var endVertexID int64
		if direction == ast.EdgeDirectionOutgoing {
			_, _, endVertexID, err = codec.ParseOutgoingEdgeKey(iter.Key())
		} else {
			_, endVertexID, _, err = codec.ParseIncomingEdgeKey(iter.Key())
		}

		edgeVar, err := m.decodeGraphVar(iter.Value())
		if err != nil {
			return err
		}
		if !matchLabels(edgeVar.Labels, edge.Labels) {
			continue
		}

		endVar, err := m.matchVertex(ctx, endVertex, endVertexID)
		if err != nil {
			return err
		}
		if endVar == nil {
			continue
		}

		if err := f(edgeVar, endVar); err != nil {
			return err
		}
	}
	return nil
}

func (m *MatchExec) matchVertex(ctx context.Context, vertex *planner.Vertex, vertexID int64) (*types.GraphVar, error) {
	graph := m.sc.CurrentGraph()
	key := codec.VertexKey(graph.Meta().ID, vertexID)
	val, err := m.txn.Get(ctx, key)
	if err != nil {
		if errors.ErrorEqual(err, kv.ErrNotExist) {
			return nil, nil
		}
		return nil, err
	}
	vertexVar, err := m.decodeGraphVar(val)
	if err != nil {
		return nil, err
	}
	vertexVar.ID = vertexID
	if !matchLabels(vertexVar.Labels, vertex.Labels) {
		return nil, nil
	}
	return vertexVar, nil
}

func (m *MatchExec) matchEdge(ctx context.Context, edge *planner.Edge, srcVertexID, dstVertexID int64) (*types.GraphVar, error) {
	graph := m.sc.CurrentGraph()
	edgeKey := codec.OutgoingEdgeKey(graph.Meta().ID, srcVertexID, dstVertexID)
	val, err := m.txn.Get(ctx, edgeKey)
	if err != nil {
		if errors.ErrorEqual(err, kv.ErrNotExist) {
			return nil, nil
		}
		return nil, err
	}
	edgeVar, err := m.decodeGraphVar(val)
	if err != nil {
		return nil, err
	}
	if !matchLabels(edgeVar.Labels, edge.Labels) {
		return nil, nil
	}
	return edgeVar, nil
}

func matchLabels(labelNames []string, labels []*catalog.Label) bool {
	if len(labels) == 0 {
		return true
	}
	return slices.ContainsFunc(labelNames, func(labelName string) bool {
		return slices.ContainsFunc(labels, func(label *catalog.Label) bool {
			return label.Meta().Name.L == labelName
		})
	})
}

func (m *MatchExec) decodeGraphVar(val []byte) (*types.GraphVar, error) {
	graph := m.sc.CurrentGraph()

	var labelInfos []*model.LabelInfo
	for _, label := range graph.Labels() {
		labelInfos = append(labelInfos, label.Meta())
	}
	dec := codec.NewPropertyDecoder(labelInfos, graph.Properties())

	labelIDs, propertyValues, err := dec.Decode(val)
	if err != nil {
		return nil, err
	}
	graphVar := &types.GraphVar{
		Properties: make(map[string]types.Datum),
	}
	for labelID := range labelIDs {
		graphVar.Labels = append(graphVar.Labels, graph.LabelByID(int64(labelID)).Meta().Name.L)
	}
	for propID, propVal := range propertyValues {
		propName := graph.PropertyByID(propID).Name.L
		graphVar.Properties[propName] = propVal
	}
	return graphVar, nil
}

func (m *MatchExec) Close() error {
	if m.txn != nil {
		return m.txn.Rollback()
	}
	return nil
}
