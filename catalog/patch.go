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

package catalog

import "github.com/vescale/zgraph/parser/model"

// PatchType represents the type of patch.
type PatchType byte

const (
	PatchTypeCreateGraph PatchType = iota
	PatchTypeCreateLabel
	PatchTypeCreateIndex
	PatchTypeDropGraph
	PatchTypeDropLabel
	PatchTypeDropIndex
)

// Patch represents patch which contains a DDL change.
type Patch struct {
	Type PatchType
	Data interface{}
}

// Apply applies the patch to catalog.
// Note: we need to ensure the DDL changes have applied to persistent storage first.
func (c *Catalog) Apply(patch *Patch) {
	switch patch.Type {
	case PatchTypeCreateGraph:
		data := patch.Data.(*model.GraphInfo)
		graph := NewGraph(data)
		c.mu.Lock()
		c.byName[data.Name.L] = graph
		c.byID[data.ID] = graph
		c.mu.Unlock()

	case PatchTypeDropGraph:
		data := patch.Data.(*model.GraphInfo)
		c.mu.Lock()
		delete(c.byName, data.Name.L)
		delete(c.byID, data.ID)
		c.mu.Unlock()
	}
}
