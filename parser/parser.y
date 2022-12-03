%{
// Copyright 2013 The ql Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSES/QL-LICENSE file.

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

// Initial yacc source generated by ebnf2y[1]
// at 2013-10-04 23:10:47.861401015 +0200 CEST
//
//  $ ebnf2y -o ql.y -oe ql.ebnf -start StatementList -pkg ql -p _
//
//   [1]: http://github.com/cznic/ebnf2y

// The parser implements the PGQL specification
//
// - https://pgql-lang.org/spec/1.5/
//

package parser

import (
	"math"

	"github.com/vescale/zgraph/parser/ast"
	"github.com/vescale/zgraph/parser/model"
	"github.com/vescale/zgraph/parser/opcode"
	"github.com/vescale/zgraph/parser/types"
)

%}

%union {
	offset int // offset
	item interface{}
	ident string
	expr ast.ExprNode
	statement ast.StmtNode
}

%token	<ident>

	/*yy:token "%c"     */
	identifier "identifier"

	/*yy:token "\"%c\"" */
	stringLit          "string literal"
	singleAtIdentifier "identifier with single leading at"
	doubleAtIdentifier "identifier with double leading at"
	invalid            "a special token never used by parser, used by lexer to indicate error"
	andand             "&&"
	pipes              "||"

	/* Reserved keywords */
	as                    "AS"
	asc                   "ASC"
	by                    "BY"
	create                "CREATE"
	defaultKwd            "DEFAULT"
	deleteKwd             "DELETE"
	desc                  "DESC"
	doubleType            "DOUBLE"
	drop                  "DROP"
	edge                  "EDGE"
	exists                "EXISTS"
	falseKwd              "FALSE"
	floatType             "FLOAT"
	from                  "FROM"
	group                 "GROUP"
	having                "HAVING"
	ifKwd                 "IF"
	index                 "INDEX"
	insert                "INSERT"
	integerType           "INTEGER"
	into                  "INTO"
	intType               "INT"
	is                    "IS"
	limit                 "LIMIT"
	match                 "MATCH"
	not                   "NOT"
	null                  "NULL"
	on                    "ON"
	order                 "ORDER"
	selectKwd             "SELECT"
	set                   "SET"
	trueKwd               "TRUE"
	unique                "UNIQUE"
	update                "UPDATE"
	use                   "USE"
	vertex                "VERTEX"
	where                 "WHERE"
	xor                   "XOR"
	or                    "OR"
	and                   "AND"
	between               "BETWEEN"
	labels                "LABELS"
	properties            "PROPERTIES"
	caseKwd               "CASE"
	then                  "THEN"
	when                  "WHEN"
	elseKwd               "ELSE"
	in                    "IN"
	distinct              "DISTINCT"

	/* Unreserved keywords. Notice: make sure these tokens are contained in UnReservedKeyword. */
	begin                 "BEGIN"
	end                   "END"
	comment               "COMMENT"
	commit                "COMMIT"
	booleanType           "BOOLEAN"
	explain               "EXPLAIN"
	yearType              "YEAR"
	dateType              "DATE"
	day                   "DAY"
	timestampType         "TIMESTAMP"
	timeType              "TIME"
	rollback              "ROLLBACK"
	offset                "OFFSET"
	graph                 "GRAPH"
	all                   "ALL"
	any                   "ANY"
	shortest              "SHORTEST"
	cheapest              "CHEAPEST"
	top                   "TOP"
	cost                  "COST"
	path                  "PATH"
	interval              "INTERVAL"
	hour                  "HOUR"
	minute                "MINUTE"
	month                 "MONTH"
	second                "SECOND"
	substring             "SUBSTRING"
	forkKwd               "FOR"
	arrayAgg              "ARRAY_AGG"
	avg                   "AVG"
	count                 "COUNT"
	listagg               "LISTAGG"
	max                   "MAX"
	min                   "MIN"
	sum                   "SUM"
	extract               "EXTRACT"
	timezoneHour          "TIMEZONE_HOUR"
	timezoneMinute       "TIMEZONE_MINUTE"
	cast                  "CAST"
	long                  "LONG"
	stringKwd             "STRING"
	with                  "WITH"
	zone                  "ZONE"
	prefix                "PREFIX"

	/* Functions */
	lower                 "LOWER"
	uppper                "UPPER"
	inDegree              "IN_DEGREE"
	javaRegexpLike        "JAVA_REGEXP_LIKE"
	label                 "LABEL"
	matchNumber           "MATCH_NUMBER"
	outDegree             "OUT_DEGREE"
	abs                   "ABS"
	ceil                  "CEIL"
	ceiling               "CEILING"
	elementNumber         "ELEMENT_NUMBER"
	floor                 "FLOOR"
	hasLabel              "HAS_LABEL"
	id                    "ID"
	allDifferent          "ALL_DIFFERENT"

%token	<item>

	/*yy:token "1.%d"   */
	floatLit "floating-point literal"

	/*yy:token "1.%d"   */
	decLit "decimal literal"

	/*yy:token "%d"     */
	intLit "integer literal"

	/*yy:token "%x"     */
	hexLit "hexadecimal literal"

	/*yy:token "%b"     */
	bitLit       "bit literal"

	andnot       "&^"
	assignmentEq ":="
	eq           "="
	ge           ">="
	le           "<="
	neq          "!="
	neqSynonym   "<>"
	nulleq       "<=>"
	paramMarker  "?"
	allProp      ".*"

	leftArrow           "<-"
	rightArrow          "->"
	edgeOutgoingLeft    "-["
	edgeOutgoingRight   "]->"
	edgeIncomingLeft    "<-["
	edgeIncomingRight   "]-"
	reachOutgoingLeft   "-/"
	reachOutgoingRight  "/->"
	reachIncomingLeft   "<-/"
	reachIncomingRight  "/-"

%type	<expr>
	Aggregation
	ArithmeticExpression
	BindVariable
	BracketedValueExpression
	CaseExpression
	CastSpecification
	CharacterSubstring
	ElseClauseOpt
	ExistsPredicate
	ExtractFunction
	FunctionInvocation
	ForStringLengthOpt
	InPredicate
	IsNotNullPredicate
	IsNullPredicate
	LengthNum
	LimitOption
	Literal
	ListaggSeparatorOpt
	LogicalExpression
	NotInPredicate
	PropertyAccess
	RelationalExpression
	ScalarSubquery
	SimpleCase
	SearchedCase
	StartPosition
	StringConcat
	StringLiteral
	Subquery
	ValueExpression
	VariableReference
	NumericLiteral
	BooleanLiteral
	DateLiteral
	TimeLiteral
	TimestampLiteral
	IntervalLiteral


%type	<statement>
	BeginStmt
	CommitStmt
	CreateGraphStmt
	CreateLabelStmt
	CreateIndexStmt
	DeleteStmt
	DropGraphStmt
	DropLabelStmt
	DropIndexStmt
	EmptyStmt
	ExplainStmt
	InsertStmt
	RollbackStmt
	SelectStmt
	Statement
	UpdateStmt
	UseStmt

%type	<ident>
	Identifier
	VariableName
	VertexReference
	FunctionName
	UnReservedKeyword

%type   <item>
	AllPropertiesPrefixOpt
	ArgumentList
	ByItem
	ByList
	CostClause
	CostClauseOpt
	DataType
	DateTimeField
	DistinctOpt
	EdgePattern
	ExpAsVar
	ExtractField
	SelectEelement
	FieldAsName
	FieldAsNameOpt
	FromClause
	GraphElementInsertion
	GraphElementInsertionList
	GraphElementUpdate
	GraphElementUpdateList
	GraphName
	GraphOnClause
	GraphOnClauseOpt
	GraphPattern
	GroupByClauseOpt
	HavingClauseOpt
	InValueList
	IntoClause
	IntoClauseOpt
	IfExists
	IfNotExists
	IndexKeyTypeOpt
	IndexName
	LabelName
	LabelNameList
	LabelPredicate
	LabelPredicateOpt
	LabelPropertyDef
	LabelPropertyList
	LabelPropertyListOpt
	LabelsAndProperties
	LabelSpecification
	LabelSpecificationOpt
	LimitClauseOpt
	MatchClause
	MatchClauseList
	Order
	OrderByClauseOpt
	PathPattern
	PathPatternList
	PathPatternMacro
	PathPatternMacroList
	PathPatternMacroOpt
	PatternQuantifier
	PatternQuantifierOpt
	PropertyAssignment
	PropertyAssignmentList
	PropertiesSpecification
	PropertiesSpecificationOpt
	PropertyName
	PropertyNameList
	PropertyOption
	PropertyOptionList
	PropertyOptionListOpt
	QuantifiedPathExpr
	ReachabilityPathExpr
	SelectClause
	SelectElementList
	SimplePathPattern
	StatementList
	ValueExpressionList
	VariableLengthPathPattern
	VariableNameOpt
	VariableReferenceList
	VariableSpec
	VertexPattern
	VertexPatternOpt
	WhenClause
	WhenClauseList
	WhereClauseOpt

%precedence empty
%precedence insert

%right '('
%left ')'
%precedence lowerThanOn
%precedence on
%right assignmentEq
%left pipes or pipesAsOr
%left xor
%left andand and
%left between
%left eq ge le neq neqSynonym '>' '<' is in
%left '|'
%left '&'
%left '-' '+'
%left '*' '/' '%' div mod
%left '^'
%left '~' neg
%right not
%precedence ','

%start	Entry

%%

Entry:
	StatementList

StatementList:
	Statement
	{
		if $1 != nil {
			parser.result = append(parser.result, $1)
		}
	}
|	StatementList ';' Statement
	{
		if $3 != nil {
			parser.result = append(parser.result, $3)
		}
	}

Statement:
	EmptyStmt
|	BeginStmt
|	CommitStmt
|	CreateGraphStmt
|	CreateLabelStmt
|	CreateIndexStmt
|	DeleteStmt
|	DropGraphStmt
|	DropLabelStmt
|	DropIndexStmt
|	ExplainStmt
|	InsertStmt
|	RollbackStmt
|	SelectStmt
|	UpdateStmt
|	UseStmt

EmptyStmt:
	/* EMPTY */
	{
		$$ = nil
	}

BeginStmt:
	"BEGIN"
	{
		$$ = &ast.BeginStmt{}
	}

CommitStmt:
	"COMMIT"
	{
		$$ = &ast.CommitStmt{}
	}

CreateGraphStmt:
	"CREATE" "GRAPH" IfNotExists GraphName
	{
		$$ = &ast.CreateGraphStmt{
			IfNotExists: $3.(bool),
			Graph:       $4.(model.CIStr),
		}
	}

CreateLabelStmt:
	"CREATE" "LABEL" IfNotExists LabelName LabelPropertyListOpt
	{
		cl := &ast.CreateLabelStmt{
			IfNotExists: $3.(bool),
			Label:       $4.(model.CIStr),
		}
		if $5 != nil {
			cl.Properties = $5.([]*ast.LabelProperty)
		}
		$$ = cl
	}


LabelPropertyListOpt:
	/* empty */
	{
		$$ = nil
	}
|	'(' LabelPropertyList ')'
	{
		$$ = $2
	}

LabelPropertyList:
	LabelPropertyDef
	{
		$$ = []*ast.LabelProperty{$1.(*ast.LabelProperty)}
	}
|	LabelPropertyList ',' LabelPropertyDef
	{
		$$ = append($1.([]*ast.LabelProperty), $3.(*ast.LabelProperty))
	}

LabelPropertyDef:
	PropertyName DataType PropertyOptionListOpt
	{
		lp := &ast.LabelProperty{
			Name: $1.(model.CIStr),
			Type: $2.(ast.DataType),
		}
		if $3 != nil {
			lp.Options = $3.([]*ast.LabelPropertyOption)
		}
		$$ = lp
	}

PropertyOptionListOpt:
	{
		$$ = nil
	}
|	PropertyOptionList

PropertyOptionList:
	PropertyOption
	{
		$$ = []*ast.LabelPropertyOption{$1.(*ast.LabelPropertyOption)}
	}
|	PropertyOptionList PropertyOption
	{
		$$ = append($1.([]*ast.LabelPropertyOption), $2.(*ast.LabelPropertyOption))
	}

PropertyOption:
	"NOT" "NULL"
	{
		$$ = &ast.LabelPropertyOption{
			Type: ast.LabelPropertyOptionTypeNotNull,
		}
	}
|	"NULL"
	{
		$$ = &ast.LabelPropertyOption{
			Type: ast.LabelPropertyOptionTypeNull,
		}
	}
|	"DEFAULT" Literal
	{
		$$ = &ast.LabelPropertyOption{
			Type: ast.LabelPropertyOptionTypeDefault,
			Data: $2,
		}
	}
|	"COMMENT" stringLit
	{
		$$ = &ast.LabelPropertyOption{
			Type: ast.LabelPropertyOptionTypeComment,
			Data: $2,
		}
	}

CreateIndexStmt:
	"CREATE" IndexKeyTypeOpt "INDEX" IfNotExists "ON" LabelName '(' PropertyNameList ')'
	{
		$$ = &ast.CreateIndexStmt{
			KeyType:     $2.(ast.IndexKeyType),
			IfNotExists: $4.(bool),
			LabelName:   $6.(model.CIStr),
			Properties:  $8.([]model.CIStr),
		}
	}

IndexKeyTypeOpt:
	{
		$$ = ast.IndexKeyTypeNone
	}
|	"UNIQUE"
	{
		$$ = ast.IndexKeyTypeUnique
	}

/******************************************************************************

 DELETE Statement Specification
 Reference: https://pgql-lang.org/spec/1.5/#delete

 ******************************************************************************/
DeleteStmt:
	PathPatternMacroOpt "DELETE" VariableReferenceList FromClause WhereClauseOpt GroupByClauseOpt HavingClauseOpt OrderByClauseOpt LimitClauseOpt
	{
		ds := &ast.DeleteStmt{
			VariableReferences:  $3.([]*ast.VariableReference),
			From:                $4.(*ast.MatchClauseList),
		}
		if $1 != nil {
			ds.PathPatternMacros = $1.([]*ast.PathPatternMacro)
		}
		if $5 != nil {
			ds.Where = $5.(ast.ExprNode)
		}
		if $6 != nil {
			ds.GroupBy = $6.(*ast.GroupByClause)
		}
		if $7 != nil {
			ds.Having = $7.(*ast.HavingClause)
		}
		if $8 != nil {
			ds.OrderBy = $8.(*ast.OrderByClause)
		}
		if $9 != nil {
			ds.Limit = $9.(*ast.LimitClause)
		}
		$$ = ds
	}

VariableReferenceList:
	VariableReference
	{
		$$ = $1
	}
|	VariableReferenceList ',' VariableReference
	{
		$$ = append($1.([]*ast.VariableReference), $3.(*ast.VariableReference))
	}

DropGraphStmt:
	"DROP" "GRAPH" IfExists GraphName
	{
		$$ = &ast.DropGraphStmt{
			IfExists: $3.(bool),
			Graph:    $4.(model.CIStr),
		}
	}

DropLabelStmt:
	"DROP" "LABEL" IfExists LabelName
	{
		$$ = &ast.DropLabelStmt{
			IfExists: $3.(bool),
			Label:    $4.(model.CIStr),
		}
	}

DropIndexStmt:
	"DROP" "INDEX" IfExists Identifier "ON" LabelName
	{
		$$ = &ast.DropIndexStmt{
			IfExists:  $3.(bool),
			IndexName: model.NewCIStr($4),
			LabelName: $6.(model.CIStr),
		}
	}

ExplainStmt:
	"EXPLAIN" SelectStmt
	{
		$$ = &ast.ExplainStmt{
			Select: $2.(*ast.SelectStmt),
		}
	}

/******************************************************************************

 INSERT Statement Specification
 Reference: https://pgql-lang.org/spec/1.5/#insert

 ******************************************************************************/
InsertStmt:
	"INSERT" IntoClauseOpt GraphElementInsertionList %prec insert
	{
		is := &ast.InsertStmt{
			Insertions: $3.([]*ast.GraphElementInsertion),
		}
		if $2 != nil {
			is.IntoGraphName = $2.(model.CIStr)
		}
		$$ = is
	}
|	PathPatternMacroOpt "INSERT" IntoClauseOpt GraphElementInsertionList FromClause WhereClauseOpt GroupByClauseOpt HavingClauseOpt OrderByClauseOpt LimitClauseOpt
	{
		is := &ast.InsertStmt{
			Insertions: $4.([]*ast.GraphElementInsertion),
			From:       $5.(*ast.MatchClauseList),
		}
		if $1 != nil {
			is.PathPatternMacros = $1.([]*ast.PathPatternMacro)
		}
		if $3 != nil {
			is.IntoGraphName = $3.(model.CIStr)
		}
		if $6 != nil {
			is.Where = $6.(ast.ExprNode)
		}
		if $7 != nil {
			is.GroupBy = $7.(*ast.GroupByClause)
		}
		if $8 != nil {
			is.Having = $8.(*ast.HavingClause)
		}
		if $9 != nil {
			is.OrderBy = $9.(*ast.OrderByClause)
		}
		if $10 != nil {
			is.Limit = $10.(*ast.LimitClause)
		}
		$$ = is
	}

IntoClauseOpt:
	{
		$$ = nil
	}
|	IntoClause

IntoClause:
	"INTO" GraphName
	{
		$$ = $2
	}

GraphElementInsertionList:
	GraphElementInsertion
	{
		$$ = []*ast.GraphElementInsertion{$1.(*ast.GraphElementInsertion)}
	}
|	GraphElementInsertionList ',' GraphElementInsertion
	{
		$$ = append($1.([]*ast.GraphElementInsertion), $3.(*ast.GraphElementInsertion))
	}

GraphElementInsertion:
	"VERTEX" VariableNameOpt LabelsAndProperties
	{
		insertion := &ast.GraphElementInsertion{
			InsertionType:       ast.InsertionTypeVertex,
			LabelsAndProperties: $3.(*ast.LabelsAndProperties),
		}
		if $2 != nil {
			insertion.VariableName = $2.(*ast.VariableReference)
		}
		$$ = insertion
	}
|	"EDGE" VariableNameOpt "BETWEEN" VertexReference "AND" VertexReference LabelsAndProperties
	{
		insertion := &ast.GraphElementInsertion{
			InsertionType:       ast.InsertionTypeEdge,
			From:                $4,
			To:                  $6,
			LabelsAndProperties: $7.(*ast.LabelsAndProperties),
		}
		if $2 != nil {
			insertion.VariableName = $2.(*ast.VariableReference)
		}
		$$ = insertion
	}

VertexReference:
	Identifier

LabelsAndProperties:
	LabelSpecificationOpt PropertiesSpecificationOpt
	{
		lps := &ast.LabelsAndProperties{}
		if $1 != nil {
			lps.Labels = $1.([]model.CIStr)
		}
		if $2 != nil {
			lps.Assignments = $2.([]*ast.PropertyAssignment)
		}
		$$ = lps
	}

LabelSpecificationOpt:
	{
		$$ = nil
	}
|	LabelSpecification

LabelSpecification:
	"LABELS" '(' LabelNameList ')'
	{
		$$ = $3
	}

PropertiesSpecificationOpt:
	{
		$$ = nil
	}
|	PropertiesSpecification

PropertiesSpecification:
	"PROPERTIES" '(' PropertyAssignmentList ')'
	{
		$$ = $3
	}

PropertyAssignmentList:
	PropertyAssignment
	{
		$$ = []*ast.PropertyAssignment{$1.(*ast.PropertyAssignment)}
	}
|	PropertyAssignmentList ',' PropertyAssignment
	{
		$$ = append($1.([]*ast.PropertyAssignment), $3.(*ast.PropertyAssignment))
	}

PropertyAssignment:
	PropertyAccess '=' ValueExpression
	{
		$$ = &ast.PropertyAssignment{
			PropertyAccess:  $1.(*ast.PropertyAccess),
			ValueExpression: $3.(ast.ExprNode),
		}
	}

PropertyAccess:
	VariableReference '.' PropertyName
	{
		$$ = &ast.PropertyAccess{
			VariableName: $1.(*ast.VariableReference),
			PropertyName: $3.(model.CIStr),
		}
	}

ValueExpression:
	VariableReference
|	PropertyAccess
|	Literal
|	BindVariable
|	ArithmeticExpression
|	RelationalExpression
|	LogicalExpression
|	StringConcat
|	BracketedValueExpression
|	FunctionInvocation
|	CharacterSubstring
|	Aggregation
|	ExtractFunction
|	IsNullPredicate
|	IsNotNullPredicate
|	CastSpecification
|	CaseExpression
|	InPredicate
|	NotInPredicate
|	ExistsPredicate
|	ScalarSubquery

VariableReference:
	VariableName
	{
		$$ = &ast.VariableReference{
			VariableName: $1,
		}
	}

Literal:
	StringLiteral
|	NumericLiteral
|	BooleanLiteral
|	DateLiteral
|	TimeLiteral
|	TimestampLiteral
|	IntervalLiteral

StringLiteral:
	stringLit
	{
		$$ = ast.NewValueExpr($1)
	}
|	hexLit
	{
		$$ = ast.NewValueExpr($1)
	}
|	bitLit
	{
		$$ = ast.NewValueExpr($1)
	}

NumericLiteral:
	intLit
	{
		$$ = ast.NewValueExpr($1)
	}
|	decLit
	{
		$$ = ast.NewValueExpr($1)
	}
|	floatLit
	{
		$$ = ast.NewValueExpr($1)
	}

BooleanLiteral:
	"FALSE"
	{
		$$ = ast.NewValueExpr(false)
	}
|	"TRUE"
	{
		$$ = ast.NewValueExpr(true)
	}

DateLiteral:
	"DATE" stringLit
	{
		d, err := types.NewDateLiteral($2)
		if err != nil {
			yylex.AppendError(err)
			return 1
		}
		$$ = ast.NewValueExpr(d)
	}

TimeLiteral:
	"TIME" stringLit
	{
		t, err := types.NewTimeLiteral($2)
		if err != nil {
			yylex.AppendError(err)
			return 1
		}
		$$ = ast.NewValueExpr(t)
	}

TimestampLiteral:
	"TIMESTAMP" stringLit
	{
		t, err := types.NewTimestampLiteral($2)
		if err != nil {
			yylex.AppendError(err)
			return 1
		}
		$$ = ast.NewValueExpr(t)
	}

IntervalLiteral:
	"INTERVAL" stringLit DateTimeField
	{
		i := &types.IntervalLiteral{
			Value: $2,
			Unit:  $3.(types.DateTimeField),
		}
		$$ = ast.NewValueExpr(i)
	}

DateTimeField:
	"YEAR"
	{
		$$ = types.DateTimeFieldYear
	}
|	"MONTH"
	{
		$$ = types.DateTimeFieldMonth
	}
|	"DAY"
	{
		$$ = types.DateTimeFieldDay
	}
|	"HOUR"
	{
		$$ = types.DateTimeFieldHour
	}
|	"MINUTE"
	{
		$$ = types.DateTimeFieldMinute
	}
|	"SECOND"
	{
		$$ = types.DateTimeFieldSecond
	}

BindVariable:
	'?'
	{
		$$ = &ast.BindVariable{}
	}

ArithmeticExpression:
	'-' ValueExpression %prec neg
	{
		$$ = &ast.UnaryOperationExpr{ Op: opcode.Minus, V:  $2}
	}
|	ValueExpression '*' ValueExpression %prec '*'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Mul, L: $1, R: $3}
	}
|	ValueExpression '/' ValueExpression %prec '/'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Div, L: $1, R: $3}
	}
|	ValueExpression '%' ValueExpression %prec '%'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Mod, L: $1, R: $3}
	}
|	ValueExpression '+' ValueExpression %prec '+'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Plus, L: $1, R: $3}
	}
|	ValueExpression '-' ValueExpression %prec '-'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Minus, L: $1, R: $3}
	}

RelationalExpression:
	ValueExpression eq ValueExpression
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.EQ, L: $1, R: $3}
	}
|	ValueExpression neqSynonym ValueExpression
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.NE, L: $1, R: $3}
	}
|	ValueExpression '>' ValueExpression
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.GT, L: $1, R: $3}
	}
|	ValueExpression '<' ValueExpression
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LT, L: $1, R: $3}
	}
|	ValueExpression ge ValueExpression
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.GE, L: $1, R: $3}
	}
|	ValueExpression le ValueExpression
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LE, L: $1, R: $3}
	}

LogicalExpression:
	ValueExpression "OR" ValueExpression %prec pipes
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LogicOr, L: $1, R: $3}
	}
|	ValueExpression "XOR" ValueExpression %prec xor
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LogicXor, L: $1, R: $3}
	}
|	ValueExpression "AND" ValueExpression %prec andand
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LogicAnd, L: $1, R: $3}
	}
|	"NOT" ValueExpression %prec not
	{
		v, ok := $2.(*ast.ExistsSubqueryExpr)
		if ok {
			v.Not = true
			$$ = $2
		} else {
			$$ = &ast.UnaryOperationExpr{ Op: opcode.Not, V:  $2}
		}
	}

StringConcat:
	ValueExpression pipes ValueExpression
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Concat, L: $1, R: $3}
	}

BracketedValueExpression:
	'(' ValueExpression ')'
	{
		$$ = &ast.ParenthesesExpr{Expr: $2}
	}

/******************************************************************************

 Reference
 - https://pgql-lang.org/spec/1.5/#user-defined-functions

 zGraph doesn't plan to support UDF and remove the PackageSpecificationOpt

 FunctionInvocation  ::= PackageSpecification? FunctionName '(' ArgumentList? ')'
 PackageSpecification::= PackageName '.'
 PackageName         ::= Identifier

 FunctionInvocation:
 	PackageSpecificationOpt FunctionName '(' ArgumentList ')'
 	{}

 PackageSpecificationOpt:
 	{}
 |	PackageName '.'
 	{}

 PackageName:
 	Identifier

 ******************************************************************************/
FunctionInvocation:
	FunctionName '(' ArgumentList ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   $3.([]ast.ExprNode),
		}
	}

FunctionName:
	"LOWER"
|	"UPPER"
|	"JAVA_REGEXP_LIKE"
|	"ABS"
|	"CEIL"
|	"CEILING"
|	"FLOOR"
|	"ID"
|	"LABEL"
|	"LABELS"
|	"HAS_LABEL"
|	"MATCH_NUMBER"
|	"ELEMENT_NUMBER"
|	"IN_DEGREE"
|	"OUT_DEGREE"
|	"ALL_DIFFERENT"

ArgumentList:
	ValueExpression
	{
		$$ = []ast.ExprNode{$1}
	}
|	ArgumentList ',' ValueExpression
	{
		$$ = append($1.([]ast.ExprNode), $3)
	}

CharacterSubstring:
	"SUBSTRING" '(' ValueExpression "FROM" StartPosition ForStringLengthOpt ')'
	{
		$$ = &ast.SubstrFuncExpr{
			Expr:  $3,
			Start: $5,
			For:   $6,
		}
	}

StartPosition:
	ValueExpression

ForStringLengthOpt:
	{
		$$ = nil
	}
|	"FOR" ValueExpression
	{
		$$ = $2
	}

Aggregation:
	"COUNT" '(' '*' ')'
	{
		$$ = &ast.AggregateFuncExpr{
			F:    $1,
			Args: []ast.ExprNode{
				ast.NewValueExpr(1),
			},
		}
	}
|	"COUNT" '(' DistinctOpt ValueExpression ')'
	{
		$$ = &ast.AggregateFuncExpr{
			F:        $1,
			Args:     []ast.ExprNode{$4},
			Distinct: $3.(bool),
		}
	}
|	"MIN" '(' DistinctOpt ValueExpression ')'
	{
		$$ = &ast.AggregateFuncExpr{
			F:        $1,
			Args:     []ast.ExprNode{$4},
			Distinct: $3.(bool),
		}
	}
|	"MAX" '(' DistinctOpt ValueExpression ')'
	{
		$$ = &ast.AggregateFuncExpr{
			F:        $1,
			Args:     []ast.ExprNode{$4},
			Distinct: $3.(bool),
		}
	}
|	"AVG" '(' DistinctOpt ValueExpression ')'
	{
		$$ = &ast.AggregateFuncExpr{
			F:        $1,
			Args:     []ast.ExprNode{$4},
			Distinct: $3.(bool),
		}
	}
|	"SUM" '(' DistinctOpt ValueExpression ')'
	{
		$$ = &ast.AggregateFuncExpr{
			F:        $1,
			Args:     []ast.ExprNode{$4},
			Distinct: $3.(bool),
		}
	}
|	"ARRAY_AGG" '(' DistinctOpt ValueExpression ')'
	{
		$$ = &ast.AggregateFuncExpr{
			F:        $1,
			Args:     []ast.ExprNode{$4},
			Distinct: $3.(bool),
		}
	}
|	"LISTAGG" '(' DistinctOpt ValueExpression ListaggSeparatorOpt')'
	{
		expr := &ast.AggregateFuncExpr{
			F:        $1,
			Args:     []ast.ExprNode{$4},
			Distinct: $3.(bool),
		}
		if $5 != nil {
			expr.Args = append(expr.Args, $5)
		}
		$$ = expr
	}

DistinctOpt:
	{
		$$ = false
	}
|	"DISTINCT"
	{
		$$ = true
	}

ListaggSeparatorOpt:
	{
		$$ = nil
	}
|	',' StringLiteral
	{
		$$ = $2
	}

ExtractFunction:
	"EXTRACT" '(' ExtractField "FROM" ValueExpression ')'
	{
		$$ = &ast.ExtractFuncExpr{
			ExtractField: $3.(ast.ExtractField),
			Expr:         $5,
		}
	}

ExtractField:
	"YEAR"
	{
		$$ = ast.ExtractFieldYear
	}
|	"MONTH"
	{
		$$ = ast.ExtractFieldMonth
	}
|	"DAY"
	{
		$$ = ast.ExtractFieldDay
	}
|	"HOUR"
	{
		$$ = ast.ExtractFieldHour
	}
|	"MINUTE"
	{
		$$ = ast.ExtractFieldMinute
	}
|	"SECOND"
	{
		$$ = ast.ExtractFieldSecond
	}
|	"TIMEZONE_HOUR"
	{
		$$ = ast.ExtractFieldTimezoneHour
	}
|	"TIMEZONE_MINUTE"
	{
		$$ = ast.ExtractFieldTimezoneMinute
	}

IsNullPredicate:
	ValueExpression "IS" "NULL"
	{
		$$ = &ast.IsNullExpr{
			Expr: $1,
		}
	}

IsNotNullPredicate:
	ValueExpression "IS" "NOT" "NULL"
	{
		$$ = &ast.IsNullExpr{
			Expr: $1,
			Not:  true,
		}
	}

CastSpecification:
	"CAST" '(' ValueExpression "AS" DataType ')'
	{
		$$ = &ast.CastFuncExpr{
			Expr:     $3,
			DataType: $5.(ast.DataType),
		}
	}

DataType:
	"STRING"
	{
		$$ = ast.DataTypeString
	}
|	"BOOLEAN"
	{
		$$ = ast.DataTypeBoolean
	}
|	"INTEGER"
	{
		$$ = ast.DataTypeInteger
	}
|	"INT"
	{
		$$ = ast.DataTypeInt
	}
|	"LONG"
	{
		$$ = ast.DataTypeLong
	}
|	"FLOAT"
	{
		$$ = ast.DataTypeFloat
	}
|	"DOUBLE"
	{
		$$ = ast.DataTypeDouble
	}
|	"DATE"
	{
		$$ = ast.DataTypeDate
	}
|	"TIME"
	{
		$$ = ast.DataTypeTime
	}
|	"TIME" "WITH" "TIME" "ZONE"
	{
		$$ = ast.DataTypeTimeWithZone
	}
|	"TIMESTAMP"
	{
		$$ = ast.DataTypeTimestamp
	}
|	"TIMESTAMP" "WITH" "TIME" "ZONE"
	{
		$$ = ast.DataTypeTimestampWithZone
	}

CaseExpression:
	SimpleCase
|	SearchedCase

SimpleCase:
	"CASE" ValueExpression WhenClauseList ElseClauseOpt "END"
	{
		$$ = &ast.CaseExpr{
			Value:       $2,
			WhenClauses: $3.([]*ast.WhenClause),
			ElseClause:  $4,
		}
	}

SearchedCase:
	"CASE" WhenClauseList ElseClauseOpt "END"
	{
		$$ = &ast.CaseExpr{
			WhenClauses: $2.([]*ast.WhenClause),
			ElseClause:  $3,
		}
	}

WhenClauseList:
	WhenClause
	{
		$$ = []*ast.WhenClause{$1.(*ast.WhenClause)}
	}
|	WhenClauseList WhenClause
	{
		$$ = append($1.([]*ast.WhenClause), $2.(*ast.WhenClause))
	}

WhenClause:
	"WHEN" ValueExpression "THEN" ValueExpression
	{
		$$ = &ast.WhenClause{
			Expr:   $2,
			Result: $4,
		}
	}

ElseClauseOpt:
	{
		$$ = nil
	}
|	"ELSE" ValueExpression
	{
		$$ = $2
	}

InPredicate:
	ValueExpression "IN" InValueList
	{
		$$ = &ast.PatternInExpr{
			Expr: $1,
			List: $3.([]ast.ExprNode),
		}
	}

NotInPredicate:
	ValueExpression "NOT" "IN" InValueList
	{
		$$ = &ast.PatternInExpr{
			Expr: $1,
			List: $4.([]ast.ExprNode),
			Not:  true,
		}
	}

InValueList:
	'(' ValueExpressionList ')'
	{
		$$ = $2
	}

ValueExpressionList:
	ValueExpression
	{
		$$ = []ast.ExprNode{$1}
	}
|	ValueExpressionList ',' ValueExpression
	{
		$$ = append($1.([]ast.ExprNode), $3)
	}

ExistsPredicate:
	"EXISTS" Subquery
	{
		$$ = &ast.ExistsSubqueryExpr{
			Sel: $2,
		}
	}

Subquery:
	'(' SelectStmt ')'
	{
		$$ = &ast.SubqueryExpr{
			Query: $2.(*ast.SelectStmt),
		}
	}

ScalarSubquery:
	Subquery

/******************************************************************************

 ROLLBACK Statement

 *****************************************************************************/
RollbackStmt:
	"ROLLBACK"
	{}

/*************************************Select Statement***************************************/
SelectStmt:
	PathPatternMacroOpt SelectClause FromClause WhereClauseOpt GroupByClauseOpt HavingClauseOpt OrderByClauseOpt LimitClauseOpt
	{
		ss := &ast.SelectStmt{
			Select: $2.(*ast.SelectClause),
			From:   $3.(*ast.MatchClauseList),
		}
		if $1 != nil {
			ss.PathPatternMacros = $1.([]*ast.PathPatternMacro)
		}
		if $4 != nil {
			ss.Where = $4.(ast.ExprNode)
		}
		if $5 != nil {
			ss.GroupBy = $5.(*ast.GroupByClause)
		}
		if $6 != nil {
			ss.Having = $6.(*ast.HavingClause)
		}
		if $7 != nil {
			ss.OrderBy = $7.(*ast.OrderByClause)
		}
		if $8 != nil {
			ss.Limit = $8.(*ast.LimitClause)
		}
		$$ = ss
	}

SelectClause:
	"SELECT" DistinctOpt SelectElementList
	{
		$$ = &ast.SelectClause{
			Distinct: $2.(bool),
			Elements: $3.([]*ast.SelectElement),
		}
	}
|	"SELECT" '*' %prec '*'
	{
		$$ = &ast.SelectClause{
			Star: true,
		}
	}

SelectElementList:
	SelectEelement
	{
		$$ = []*ast.SelectElement{$1.(*ast.SelectElement)}
	}
|	SelectElementList ',' SelectEelement
	{
		$$ = append($1.([]*ast.SelectElement), $3.(*ast.SelectElement))
	}

SelectEelement:
	ExpAsVar
	{
		$$ = &ast.SelectElement{
			ExpAsVar: $1.(*ast.ExpAsVar),
		}
	}
|	Identifier allProp AllPropertiesPrefixOpt %prec '*'
	{
		$$ = &ast.SelectElement{
			Identifier: $1,
			Prefix:     $3.(string),
		}
	}

ExpAsVar:
	ValueExpression FieldAsNameOpt
	{
		ev := &ast.ExpAsVar{
			Expr: $1.(ast.ExprNode),
		}
		if $2 != nil {
			ev.AsName = $2.(model.CIStr)
		}
		$$ = ev
	}

AllPropertiesPrefixOpt:
	%prec empty
	{
		$$ = ""
	}
|	"PREFIX" StringLiteral
	{
		$$ = $1
	}

FieldAsNameOpt:
	/* EMPTY */
	{
		$$ = nil
	}
|	FieldAsName
	{
		$$ = $1.(model.CIStr)
	}

FieldAsName:
	"AS" Identifier
	{
		$$ = model.NewCIStr($2)
	}
|	"AS" stringLit
	{
		$$ = model.NewCIStr($2)
	}

FromClause:
	"FROM" MatchClauseList
	{
		$$ = $2.(*ast.MatchClauseList)
	}

MatchClauseList:
	MatchClause
	{
		$$ = &ast.MatchClauseList{
			Matches: []*ast.MatchClause{$1.(*ast.MatchClause)},
		}
	}
|	MatchClauseList ',' MatchClause
	{
		ml := $1.(*ast.MatchClauseList)
		ml.Matches = append(ml.Matches, $3.(*ast.MatchClause))
		$$ = ml
	}

MatchClause:
	"MATCH" GraphPattern GraphOnClauseOpt RowsPerMatchOpt
	{
		mc := &ast.MatchClause{
			Paths: $2.([]*ast.PathPattern),
		}
		if $3 != nil {
			mc.Graph = $3.(model.CIStr)
		}
		$$ = mc
	}

GraphOnClause:
	"ON" GraphName
	{
		$$ = $2.(model.CIStr)
	}

GraphOnClauseOpt:
	%prec lowerThanOn
	{
		$$ = nil
	}
|	GraphOnClause

RowsPerMatchOpt:
	{}

GraphPattern:
	PathPattern
	{
		$$ = []*ast.PathPattern{$1.(*ast.PathPattern)}
	}
|	'(' PathPatternList ')'
	{
		$$ = $2.([]*ast.PathPattern)
	}

PathPatternList:
	PathPattern
	{
		$$ = $1.(*ast.PathPattern)
	}
|	PathPatternList ',' PathPattern
	{
		$$ = append($1.([]*ast.PathPattern), $3.(*ast.PathPattern))
	}

PathPattern:
	SimplePathPattern
	{
		pp := $1.(*ast.PathPattern)
		pp.Tp = ast.PathPatternSimple
		$$ = pp
	}
|	"ANY" VariableLengthPathPattern
	{
		pp := $2.(*ast.PathPattern)
		pp.Tp = ast.PathPatternAny
		$$ = pp
	}
|	"ANY" "SHORTEST" VariableLengthPathPattern
	{
		pp := $3.(*ast.PathPattern)
		pp.Tp = ast.PathPatternAnyShortest
		$$ = pp
	}
|	"ALL" "SHORTEST" VariableLengthPathPattern
	{
		pp := $3.(*ast.PathPattern)
		pp.Tp = ast.PathPatternAllShortest
		$$ = pp
	}
|	"TOP" intLit "SHORTEST" VariableLengthPathPattern
	{
		pp := $4.(*ast.PathPattern)
		pp.Tp = ast.PathPatternTopKShortest
		pp.TopK = $2.(int64)
		$$ = pp
	}
|	"ANY" "CHEAPEST" VariableLengthPathPattern
	{
		pp := $3.(*ast.PathPattern)
		pp.Tp = ast.PathPatternAnyCheapest
		$$ = pp
	}
|	"ALL" "CHEAPEST" VariableLengthPathPattern
	{
		pp := $3.(*ast.PathPattern)
		pp.Tp = ast.PathPatternAllCheapest
		$$ = pp
	}
|	"TOP" intLit "CHEAPEST" VariableLengthPathPattern
	{
		pp := $4.(*ast.PathPattern)
		pp.Tp = ast.PathPatternTopKCheapest
		pp.TopK = $2.(int64)
		$$ = pp
	}
|	"ALL" VariableLengthPathPattern
	{
		pp := $2.(*ast.PathPattern)
		pp.Tp = ast.PathPatternAll
		$$ = pp
	}

SimplePathPattern:
	VertexPattern
	{
		$$ = &ast.PathPattern{Vertices: []*ast.VertexPattern{$1.(*ast.VertexPattern)}}
	}
|	SimplePathPattern ReachabilityPathExpr VertexPattern
	{
		pp := $1.(*ast.PathPattern)
		pp.Vertices = append(pp.Vertices, $3.(*ast.VertexPattern))
		pp.Connections = append(pp.Connections, $2.(*ast.ReachabilityPathExpr))
		$$ = pp
	}
|	SimplePathPattern EdgePattern VertexPattern
	{
		pp := $1.(*ast.PathPattern)
		pp.Vertices = append(pp.Vertices, $3.(*ast.VertexPattern))
		pp.Connections = append(pp.Connections, $2.(*ast.EdgePattern))
		$$ = pp
	}

VariableLengthPathPattern:
	VertexPattern QuantifiedPathExpr VertexPattern
	{
		$$ = &ast.PathPattern{
			Vertices:    []*ast.VertexPattern{$1.(*ast.VertexPattern), $3.(*ast.VertexPattern)},
			Connections: []ast.VertexPairConnection{$2.(*ast.QuantifiedPathExpr)},
		}
	}

ReachabilityPathExpr:
	"-/" LabelPredicate PatternQuantifierOpt "/->"
	{
		$$ = &ast.ReachabilityPathExpr{
			Labels:     $2.([]model.CIStr),
			Direction:  ast.EdgeDirectionOutgoing,
			Quantifier: $3.(*ast.PatternQuantifier),
		}
	}
|	"<-/" LabelPredicate PatternQuantifierOpt "/-"
	{
		$$ = &ast.ReachabilityPathExpr{
			Labels:     $2.([]model.CIStr),
			Direction:  ast.EdgeDirectionIncoming,
			Quantifier: $3.(*ast.PatternQuantifier),
		}
	}
|	"-/" LabelPredicate PatternQuantifierOpt "/-"
	{
		$$ = &ast.ReachabilityPathExpr{
			Labels:     $2.([]model.CIStr),
			Direction:  ast.EdgeDirectionAnyDirected,
			Quantifier: $3.(*ast.PatternQuantifier),
		}
	}

VertexPattern:
	'(' VariableSpec ')'
	{
		$$ = &ast.VertexPattern{Variable: $2.(*ast.VariableSpec)}
	}

VertexPatternOpt:
	{
		$$ = (*ast.VertexPattern)(nil)
	}
|	VertexPattern

EdgePattern:
	"-[" VariableSpec "]->"
	{
		$$ = &ast.EdgePattern{
			Variable:  $2.(*ast.VariableSpec),
			Direction: ast.EdgeDirectionOutgoing,
		}
	}
|	"->"
	{
		$$ = &ast.EdgePattern{Direction: ast.EdgeDirectionOutgoing}
	}
|	"<-[" VariableSpec "]-"
	{
		$$ = &ast.EdgePattern{
			Variable:  $2.(*ast.VariableSpec),
			Direction: ast.EdgeDirectionIncoming,
		}
	}
|	"<-"
	{
		$$ = &ast.EdgePattern{Direction: ast.EdgeDirectionIncoming}
	}
|	"-[" VariableSpec "]-"
	{
		$$ = &ast.EdgePattern{
			Variable:  $2.(*ast.VariableSpec),
			Direction: ast.EdgeDirectionAnyDirected,
		}
	}
|	'-'
	{
		$$ = &ast.EdgePattern{Direction: ast.EdgeDirectionAnyDirected}
	}

VariableSpec:
	VariableNameOpt LabelPredicateOpt
	{
		v := &ast.VariableSpec{
			Name:   $1.(model.CIStr),
			Labels: $2.([]model.CIStr),
		}
		if v.Name.L == "" {
			v.Anonymous = true
		}
		$$ = v
	}

VariableNameOpt:
	{
		$$ = model.CIStr{}
	}
|	Identifier
	{
		$$ = model.NewCIStr($1)
	}

LabelPredicate:
	ColonOrIsKeyword LabelNameList
	{
		$$ = $2.([]model.CIStr)
	}

LabelPredicateOpt:
	{
		$$ = []model.CIStr(nil)
	}
|	LabelPredicate

ColonOrIsKeyword:
	':'
|	"IS"

LabelNameList:
	LabelName
	{
		$$ = []model.CIStr{$1.(model.CIStr)}
	}
|	LabelNameList '|' LabelName
	{
		$$ = append($1.([]model.CIStr), $3.(model.CIStr))
	}

QuantifiedPathExpr:
	EdgePattern PatternQuantifierOpt
	{
		$$ = &ast.QuantifiedPathExpr{
			Edge:       $1.(*ast.EdgePattern),
			Quantifier: $2.(*ast.PatternQuantifier),
		}
	}
|	'(' VertexPatternOpt EdgePattern VertexPatternOpt WhereClauseOpt CostClauseOpt ')' PatternQuantifierOpt
	{
		q := &ast.QuantifiedPathExpr{
			Edge:        $3.(*ast.EdgePattern),
			Quantifier:  $8.(*ast.PatternQuantifier),
			Source:      $2.(*ast.VertexPattern),
			Destination: $4.(*ast.VertexPattern),
		}
		if $5 != nil {
			q.Where = $5.(ast.ExprNode)
		}
		if $6 != nil {
			q.Cost = $6.(ast.ExprNode)
		}
		$$ = q
	}

CostClause:
	"COST" ValueExpression
	{
		$$ = $2.(ast.ExprNode)
	}

CostClauseOpt:
	{
		$$ = nil
	}
|	CostClause

PatternQuantifier:
	'*'
	{
		$$ = &ast.PatternQuantifier{Tp: ast.PatternQuantifierZeroOrMore, M: math.MaxInt64}
	}
|	'+'
	{
		$$ = &ast.PatternQuantifier{Tp: ast.PatternQuantifierOneOrMore, N: 1, M: math.MaxInt64}
	}
// '?' is declared as paramMarker before.
|	paramMarker
	{
		$$ = &ast.PatternQuantifier{Tp: ast.PatternQuantifierOptional, N: 0, M: 1}
	}
|	'{' intLit '}'
	{
		$$ = &ast.PatternQuantifier{Tp: ast.PatternQuantifierExactlyN, N: $2.(int64), M: $2.(int64)}
	}
|	'{' intLit ',' '}'
	{
		$$ = &ast.PatternQuantifier{Tp: ast.PatternQuantifierNOrMore, N: $2.(int64), M: math.MaxInt64}
	}
|	'{' intLit ',' intLit '}'
	{
		$$ = &ast.PatternQuantifier{Tp: ast.PatternQuantifierBetweenNAndM, N: $2.(int64), M: $4.(int64)}
	}
|	'{' ',' intLit '}'
	{
		$$ = &ast.PatternQuantifier{Tp: ast.PatternQuantifierBetweenZeroAndM, N: 0, M: $3.(int64)}
	}

PatternQuantifierOpt:
	{
		$$ = (*ast.PatternQuantifier)(nil)
	}
|	PatternQuantifier

PathPatternMacroOpt:
	%prec empty
	{
		$$ = nil
	}
|	PathPatternMacroList

PathPatternMacroList:
	PathPatternMacro
	{
		$$ = []*ast.PathPatternMacro{$1.(*ast.PathPatternMacro)}
	}
|	PathPatternMacroList PathPatternMacro
	{
		$$ = append($1.([]*ast.PathPatternMacro), $2.(*ast.PathPatternMacro))
	}

PathPatternMacro:
	"PATH" Identifier "AS" PathPattern WhereClauseOpt
	{
		p := &ast.PathPatternMacro{
			Name: model.NewCIStr($2),
			Path: $4.(*ast.PathPattern),
		}
		if $5 != nil {
			p.Where = $5.(ast.ExprNode)
		}
		$$ = p
	}

WhereClauseOpt:
 	{
 		$$ = nil
 	}
|	"WHERE" ValueExpression
	{
		$$ = $2
	}

GroupByClauseOpt:
 	{
 		$$ = nil
 	}
|	"GROUP" "BY" ByList
	{
		$$ = &ast.GroupByClause{Items: $3.([]*ast.ByItem)}
	}

ByList:
	ByItem
	{
		$$ = []*ast.ByItem{$1.(*ast.ByItem)}
	}
|	ByList ',' ByItem
	{
		$$ = append($1.([]*ast.ByItem), $3.(*ast.ByItem))
	}

ByItem:
	ExpAsVar
	{
		$$ = &ast.ByItem{
			Expr: $1.(*ast.ExpAsVar),
			NullOrder: true,
		}
	}
|	ExpAsVar Order
	{
		$$ = &ast.ByItem{
			Expr: $1.(*ast.ExpAsVar),
			Desc: $2.(bool),
		}
	}

Order:
	"ASC"
	{
		$$ = false
	}
|	"DESC"
	{
		$$ = true
	}

HavingClauseOpt:
	{
		$$ = nil
	}
|	"HAVING" ValueExpression
	{
		$$ = &ast.HavingClause{
			Expr: $2,
		}
	}

OrderByClauseOpt:
 	{
 		$$ = nil
 	}
|	"ORDER" "BY" ByList
	{
		$$ = &ast.OrderByClause{
			Items: $3.([]*ast.ByItem),
		}
	}

LimitClauseOpt:
 	{
 		$$ = nil
 	}
|	"LIMIT" LimitOption
	{
		$$ = &ast.LimitClause{
			Count: $2,
		}
	}
|	"LIMIT" LimitOption ',' LimitOption
	{
		$$ = &ast.LimitClause{
			Count:  $4.(ast.ExprNode),
			Offset: $2.(ast.ExprNode),
		}
	}
|	"LIMIT" LimitOption "OFFSET" LimitOption
	{
		$$ = &ast.LimitClause{
			Count:  $2.(ast.ExprNode),
			Offset: $4.(ast.ExprNode),
		}
	}

LimitOption:
	LengthNum
|	paramMarker
	{
		$$ = &ast.BindVariable{}
	}

LengthNum:
	intLit
	{
		$$ = ast.NewValueExpr($1)
	}

/******************************************************************************

 UPDATE Statement Specification
 Reference: https://pgql-lang.org/spec/1.5/#update

 ******************************************************************************/
UpdateStmt:
	PathPatternMacroOpt "UPDATE" GraphElementUpdateList FromClause  WhereClauseOpt GroupByClauseOpt HavingClauseOpt OrderByClauseOpt LimitClauseOpt
	{
		us := &ast.UpdateStmt{
			Updates:  $3.([]*ast.GraphElementUpdate),
			From:     $4.(*ast.MatchClauseList),
		}
		if $1 != nil {
			us.PathPatternMacros = $1.([]*ast.PathPatternMacro)
		}
		if $5 != nil {
			us.Where = $5.(ast.ExprNode)
		}
		if $6 != nil {
			us.GroupBy = $6.(*ast.GroupByClause)
		}
		if $7 != nil {
			us.Having = $7.(*ast.HavingClause)
		}
		if $8 != nil {
			us.OrderBy = $8.(*ast.OrderByClause)
		}
		if $9 != nil {
			us.Limit = $9.(*ast.LimitClause)
		}
		$$ = us
	}

GraphElementUpdateList:
	GraphElementUpdate
	{
		$$ = []*ast.GraphElementUpdate{$1.(*ast.GraphElementUpdate)}
	}
|	GraphElementUpdateList ',' GraphElementUpdate
	{
		$$ = append($1.([]*ast.GraphElementUpdate), $3.(*ast.GraphElementUpdate))
	}

GraphElementUpdate:
	VariableReference "SET" '(' PropertyAssignmentList ')'
	{
		$$ = &ast.GraphElementUpdate{
			VariableName: $1.(*ast.VariableReference),
			Assignments:  $4.([]*ast.PropertyAssignment),
		}
	}

UseStmt:
	"USE" GraphName
	{
		$$ = &ast.UseStmt{}
	}

IfExists:
	{
		$$ = false
	}
|	"IF" "EXISTS"
	{
		$$ = true
	}

IfNotExists:
	{
		$$ = false
	}
|	"IF" "NOT" "EXISTS"
	{
		$$ = true
	}

GraphName:
	Identifier
	{
		$$ = model.NewCIStr($1)
	}

PropertyName:
	Identifier
	{
		$$ = model.NewCIStr($1)
	}

IndexName:
	Identifier
	{
		$$ = model.NewCIStr($1)
	}

LabelName:
	Identifier
	{
		$$ = model.NewCIStr($1)
	}

VariableName:
	Identifier

Identifier:
	identifier
|	UnReservedKeyword

UnReservedKeyword:
	"BEGIN"
|	"END"
|	"COMMIT"
|	"BOOLEAN"
|	"EXPLAIN"
|	"YEAR"
|	"DATE"
|	"DAY"
|	"TIMESTAMP"
|	"TIME"
|	"ROLLBACK"
|	"OFFSET"
|	"GRAPH"
|	"ALL"
|	"ANY"
|	"SHORTEST"
|	"CHEAPEST"
|	"TOP"
|	"COST"
|	"PATH"
|	"INTERVAL"
|	"HOUR"
|	"MINUTE"
|	"MONTH"
|	"SECOND"
|	"SUBSTRING"
|	"FOR"
|	"ARRAY_AGG"
|	"AVG"
|	"COUNT"
|	"LISTAGG"
|	"MAX"
|	"MIN"
|	"SUM"
|	"EXTRACT"
|	"TIMEZONE_HOUR"
|	"TIMEZONE_MINUTE"
|	"CAST"
|	"LONG"
|	"STRING"
|	"WITH"
|	"ZONE"
|	"PREFIX"

PropertyNameList:
	PropertyName
|	PropertyNameList ',' PropertyName
	{
		$$ = append($1.([]model.CIStr), $3.(model.CIStr))
	}

%%
