class_name ESCGrammarStmts


class Var extends ESCGrammarStmt:
	var _name: ESCToken
	var _initializer: ESCGrammarExpr


	func init(name: ESCToken, initializer: ESCGrammarExpr):
		_name = name
		_initializer = initializer


	func accept(visitor):
		return visitor.visitVarStmt(self)


class Event extends ESCGrammarStmt:
	var _name: ESCToken
	var _flags: Array


	func init(name: ESCToken, flags: Array):
		_name = name
		_flags = flags


	func accept(visitor):
		return visitor.visitEventStmt(self)


class Block extends ESCGrammarStmt:
	var _statements: Array


	func init(statements: Array):
		_statements = statements


	func accept(visitor):
		return visitor.visitBlockStmt(self)


class ESCExpression extends ESCGrammarStmt:
	var _expression: ESCGrammarExpr


	func init(expression: ESCGrammarExpr):
		_expression = expression


	func accept(visitor):
		return visitor.visitExpressionStmt(self)
