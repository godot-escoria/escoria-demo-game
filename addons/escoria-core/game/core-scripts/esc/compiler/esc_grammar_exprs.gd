class_name ESCGrammarExprs


class Logical extends ESCGrammarExpr:
	var _left: ESCGrammarExpr
	var _operator: ESCToken
	var _right: ESCGrammarExpr


	func init(left: ESCGrammarExpr, operator: ESCToken, right: ESCGrammarExpr):
		_left = left
		_operator = operator
		_right = right


	func accept(visitor):
		return visitor.visitLogicalExpr(self)


class Binary extends ESCGrammarExpr:
	var _left: ESCGrammarExpr
	var _operator: ESCToken
	var _right: ESCGrammarExpr


	func init(left: ESCGrammarExpr, operator: ESCToken, right: ESCGrammarExpr):
		_left = left
		_operator = operator
		_right = right


	func accept(visitor):
		return visitor.visitBinaryExpr(self)


class Unary extends ESCGrammarExpr:
	var _operator: ESCToken
	var _right: ESCGrammarExpr


	func init(operator: ESCToken, right: ESCGrammarExpr):
		_operator = operator
		_right = right


	func accept(visitor):
		return visitor.visitUnaryExpr(self)


class Get extends ESCGrammarExpr:
	var _object: ESCGrammarExpr
	var _name: ESCToken


	func init(object: ESCGrammarExpr, name: ESCToken):
		_object = object
		_name = name


	func accept(visitor):
		return visitor.visitGetExpr(self)


	func get_object() -> ESCGrammarExpr:
		return _object


	func get_name() -> ESCToken:
		return _name


class Set extends ESCGrammarExpr:
	var _object: ESCGrammarExpr
	var _name: ESCToken
	var _value: ESCGrammarExpr


	func init(object: ESCGrammarExpr, name: ESCToken, value: ESCGrammarExpr):
		_object = object
		_name = name
		_value = value


	func accept(visitor):
		return visitor.visitSetExpr(self)


class Call extends ESCGrammarExpr:
	var _callee: ESCGrammarExpr
	var _paren: ESCToken
	var _arguments: Array


	func init(callee: ESCGrammarExpr, paren: ESCToken, arguments: Array):
		_callee = callee
		_paren = paren
		_arguments = arguments


	func accept(visitor):
		return visitor.visitCallExpr(self)


class Literal extends ESCGrammarExpr:
	var _value


	func init(value):
		_value = value


	func accept(visitor):
		return visitor.visitLiteralExpr(self)


class Variable extends ESCGrammarExpr:
	var _name: ESCToken


	func init(name: ESCToken):
		_name = name


	func accept(visitor):
		return visitor.visitVariableExpr(self)


	func get_name() -> ESCToken:
		return _name


class Assign extends ESCGrammarExpr:
	var _name: ESCToken
	var _value: ESCGrammarExpr


	func init(name: ESCToken, value: ESCGrammarExpr):
		_name = name
		_value = value


	func accept(visitor):
		return visitor.vistAssignExpr(self)


class Grouping extends ESCGrammarExpr:
	var _expression: ESCGrammarExpr


	func init(expression: ESCGrammarExpr):
		_expression = expression


	func accept(visitor):
		return visitor.visitGroupingExpr(self)
