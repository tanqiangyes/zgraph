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

package expression

import (
	"github.com/vescale/zgraph/parser/model"
	"github.com/vescale/zgraph/parser/types"
)

// Property represents the accessor of vertex/edge's property.
type Property struct {
	RetType  types.Datum
	Property *model.PropertyInfo
}

func (f *Property) Clone() *Property {
	fc := *f
	return &fc
}

// String implements the fmt.Stringer interface
func (f *Property) String() string {
	return ""
}
