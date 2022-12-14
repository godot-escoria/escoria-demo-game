extends Reference
class_name ESCResolver


var _interpreter: ESCInterpreter
var _scopes: Array = []


func _init(interpreter: ESCInterpreter) -> void:
	_interpreter = interpreter


func resolve(statements: Array):
	var ret = null

	for stmt in statements:
		ret = _resolve_stmt(stmt)

		# TODO: Error handling?


func visitEventStmt(stmt: ESCGrammarStmts.Event):
	pass


func visitBlockStmt(stmt: ESCGrammarStmts.Block):
	_begin_scope()

	resolve(stmt.get_statements())

	_end_scope()


func visitExpressionStmt(stmt: ESCGrammarStmts.ESCExpression):
	_resolve_expr(stmt.get_expression())


func visitIfStmt(stmt: ESCGrammarStmts.If):
	_resolve_expr(stmt.get_condition())
	_resolve_stmt(stmt.get_then_branch())

	for branch in stmt.get_elif_branches():
		_resolve_expr(branch.get_condition())
		_resolve_stmt(branch.get_then_branch())

	if stmt.get_else_branch():
		_resolve_stmt(stmt.get_else_branch())


func visitVarStmt(stmt: ESCGrammarStmts.Var):
	_declare(stmt.get_name())

	if stmt.get_initializer():
		_resolve_expr(stmt.get_initializer())

	_define(stmt.get_name())


func visitLiteralExpr(expr: ESCGrammarExprs.Literal):
	pass


func visitCallExpr(expr: ESCGrammarExprs.Call):
	_resolve_expr(expr.get_callee())

	for arg in expr.get_arguments():
		_resolve_expr(arg)


func visitAssignExpr(expr: ESCGrammarExprs.Assign):
	_resolve_expr(expr.get_value())
	_resolve_local(expr, expr.get_name())


func visitBinaryExpr(expr: ESCGrammarExprs.Binary):
	_resolve_expr(expr.get_left())
	_resolve_expr(expr.get_right())


func visitLogicalExpr(expr: ESCGrammarExprs.Logical):
	_resolve_expr(expr.get_left())
	_resolve_expr(expr.get_right())


func visitGetExpr(expr: ESCGrammarExprs.Get):
	_resolve_expr(expr.get_object())


func visitSetExpr(expr: ESCGrammarExprs.Set):
	_resolve_expr(expr.get_object())
	_resolve_expr(expr.get_value())


func visitGroupingExpr(expr: ESCGrammarExprs.Grouping):
	_resolve_expr(expr.get_expression())


func visitUnaryExpr(expr: ESCGrammarExprs.Unary):
	_resolve_expr(expr.get_right())


func visitVariableExpr(expr: ESCGrammarExprs.Variable):
	if not _scopes.empty() \
		and _scopes.front().has(expr.get_name().get_lexeme()) \
		and not _scopes.front()[expr.get_name().get_lexeme()]:

		escoria.logger.error(
			self,
			"Can't read local variable in own initializer."
		)

	_resolve_local(expr, expr.get_name())


# Private methods

func _resolve_stmt(stmt: ESCGrammarStmt):
	return stmt.accept(self)


func _resolve_expr(expr: ESCGrammarExpr):
	return expr.accept(self)


func _begin_scope():
	_scopes.push_front({})


func _end_scope():
	_scopes.pop_front()


func _declare(name: ESCToken):
	if _scopes.empty():
		return

	var scope: Dictionary = _scopes.front()

	if scope.has(name.get_lexeme()):
		# TODO: Better error handling
		escoria.logger.error(
			self,
			"Already a variable with name '%s' in this scope." % name.get_lexeme()
		)

	scope[name.get_lexeme()] = false


func _define(name: ESCToken):
	if _scopes.empty():
		return

	_scopes.front()[name.get_lexeme()] = true


func _resolve_local(expr: ESCGrammarExpr, name: ESCToken):
	for i in range(_scopes.size() - 1, -1, -1):
		if _scopes[i].has(name.get_lexeme()):
			_interpreter.resolve(expr, _scopes.size() - 1 - i)

