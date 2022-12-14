class_name ESCGrammarStmts


class Var extends ESCGrammarStmt:
	var _name: ESCToken setget ,get_name
	var _initializer: ESCGrammarExpr setget ,get_initializer


	func init(name: ESCToken, initializer: ESCGrammarExpr):
		_name = name
		_initializer = initializer


	func get_name() -> ESCToken:
		return _name


	func get_initializer() -> ESCGrammarExpr:
		return _initializer


	func accept(visitor):
		return visitor.visitVarStmt(self)


class Event extends ESCGrammarStmt:
	var _name: ESCToken setget ,get_name
	var _flags: Array setget ,get_flags


	func init(name: ESCToken, flags: Array):
		_name = name
		_flags = flags


	func get_name() -> ESCToken:
		return _name


	func get_flags() -> Array:
		return _flags


	func accept(visitor):
		return visitor.visitEventStmt(self)


class Block extends ESCGrammarStmt:
	var _statements: Array setget ,get_statements


	func init(statements: Array):
		_statements = statements


	func get_statements() -> Array:
		return _statements


	func accept(visitor):
		return visitor.visitBlockStmt(self)


class ESCExpression extends ESCGrammarStmt:
	var _expression: ESCGrammarExpr setget ,get_expression


	func init(expression: ESCGrammarExpr):
		_expression = expression


	func get_expression() -> ESCGrammarExpr:
		return _expression


	func accept(visitor):
		return visitor.visitExpressionStmt(self)


class If extends ESCGrammarStmt:
	var _condition: ESCGrammarExpr setget ,get_condition
	var _then_branch: ESCGrammarStmt setget ,get_then_branch
	var _elif_branches: Array setget ,get_elif_branches
	var _else_branch: ESCGrammarStmt setget ,get_else_branch


	func init(condition: ESCGrammarExpr, then_branch: ESCGrammarStmt, elif_branches: Array, else_branch: ESCGrammarStmt):
		_condition = condition
		_then_branch = then_branch
		_elif_branches = elif_branches
		_else_branch = else_branch


	func get_condition() -> ESCGrammarExpr:
		return _condition


	func get_then_branch() -> ESCGrammarStmt:
		return _then_branch


	func get_elif_branches() -> Array:
		return _elif_branches


	func get_else_branch() -> ESCGrammarStmt:
		return _else_branch


	func accept(visitor):
		return visitor.visitIfStmt(self)
