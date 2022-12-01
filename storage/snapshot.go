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

package storage

import (
	"context"

	"github.com/cockroachdb/pebble"
	"github.com/pingcap/errors"
	"github.com/vescale/zgraph/storage/kv"
	"github.com/vescale/zgraph/storage/mvcc"
	"github.com/vescale/zgraph/storage/resolver"
)

// KVSnapshot represent the MVCC snapshot of the low-level key/value store.
// All values read from the KVSnapshot will be checked via mvcc.Version.
// And only the committed key/values can be retrieved or iterated.
type KVSnapshot struct {
	db       *pebble.DB
	ver      mvcc.Version
	resolver *resolver.Scheduler
	resolved []mvcc.Version
}

// Get implements the Snapshot interface.
func (s *KVSnapshot) Get(_ context.Context, key kv.Key) ([]byte, error) {
	return s.get(key)
}

// Iter implements the Snapshot interface.
func (s *KVSnapshot) Iter(lowerBound kv.Key, upperBound kv.Key) (Iterator, error) {
	// The lower-level database stored key-value with versions. We need
	// to append the startVer to the raw keys.
	var start, end mvcc.Key
	if len(lowerBound) > 0 {
		start = mvcc.Encode(lowerBound, mvcc.LockVer)
	}
	if len(upperBound) > 0 {
		end = mvcc.Encode(upperBound, mvcc.LockVer)
	}

	inner := s.db.NewIter(&pebble.IterOptions{
		LowerBound: start,
		UpperBound: end,
	})

	// Ignore the return boolean value of positioning the cursor of the iterator
	// to the first key/value. The inner iterator status of the field `valid` will
	// be same as the returned value of `inner.First()`. So it will be checked
	// while the `Next` method calling.
	_ = inner.First()

	iter := &SnapshotIter{
		inner: inner,
		ver:   s.ver,
	}

	// Handle startKey is nil, in this case, the real startKey
	// should be changed the first key of the lower-level database.
	if inner.Valid() {
		key, _, err := mvcc.Decode(inner.Key())
		if err != nil {
			// Close the inner SnapshotIter if error encountered.
			_ = inner.Close()
			return nil, err
		}
		iter.nextKey = key
	}

	return iter, iter.Next()
}

// IterReverse implements the Snapshot interface.
func (s *KVSnapshot) IterReverse(lowerBound kv.Key, upperBound kv.Key) (Iterator, error) {
	var start, end mvcc.Key
	if len(lowerBound) > 0 {
		start = mvcc.Encode(lowerBound, mvcc.LockVer)
	}
	if len(upperBound) > 0 {
		end = mvcc.Encode(upperBound, mvcc.LockVer)
	}

	inner := s.db.NewIter(&pebble.IterOptions{
		LowerBound: start,
		UpperBound: end,
	})

	// Ignore the return boolean value of positioning the cursor of the iterator
	// to the last key/value. The inner iterator status of the field `valid` will
	// be same as the returned value of `inner.Last()`. So it will be checked
	// while the `Next` method calling.
	_ = inner.Last()

	iter := &SnapshotReverseIter{
		inner: inner,
		ver:   s.ver,
	}

	// Set the next key to the last valid key between lowerBound and upperBound.
	if inner.Valid() {
		key, _, err := mvcc.Decode(inner.Key())
		if err != nil {
			_ = inner.Close()
			return nil, err
		}
		iter.nextKey = key
	}

	return iter, iter.Next()
}

func (s *KVSnapshot) BatchGet(_ context.Context, keys []kv.Key) (map[string][]byte, error) {
	results := map[string][]byte{}
	for _, key := range keys {
		value, err := s.get(key)
		if err != nil {
			// TODO: backoff if locked keys encountered.
			//locked, ok := err.(*LockedError)
			//if !ok {
			//	return nil, err
			//}
			return nil, err
		}
		results[string(key)] = value
	}

	// TODO: resolve locks and backoff

	return results, nil
}

func (s *KVSnapshot) get(key kv.Key) ([]byte, error) {
	iter := s.db.NewIter(&pebble.IterOptions{LowerBound: mvcc.Encode(key, mvcc.LockVer)})
	defer iter.Close()

	// NewIter returns an SnapshotIter that is unpositioned (Iterator.Valid() will
	// return false). We must to call First or Last to position the SnapshotIter.
	if ok := iter.First(); !ok {
		return nil, errors.New("invalid key")
	}

	val, err := getValue(iter, key, s.ver, s.resolved)
	if lock, ok := err.(*mvcc.LockedError); ok {

	}
}

func getValue(iter *pebble.Iterator, key kv.Key, startVer mvcc.Version, resolvedLocks []mvcc.Version) ([]byte, error) {
	dec1 := mvcc.LockDecoder{ExpectKey: key}
	ok, err := dec1.Decode(iter)
	if ok {
		startVer, err = dec1.Lock.Check(startVer, key, resolvedLocks)
	}
	if err != nil {
		return nil, err
	}
	dec2 := mvcc.ValueDecoder{ExpectKey: key}
	for iter.Valid() {
		ok, err := dec2.Decode(iter)
		if err != nil {
			return nil, err
		}
		if !ok {
			break
		}

		value := &dec2.Value
		if value.Type == mvcc.ValueTypeRollback ||
			value.Type == mvcc.ValueTypeLock {
			continue
		}
		// Read the first committed value that can be seen at startVer.
		if value.CommitVer <= startVer {
			if value.Type == mvcc.ValueTypeDelete {
				return nil, nil
			}
			return value.Value, nil
		}
	}
	return nil, nil
}
