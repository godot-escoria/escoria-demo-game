extends Reference
class_name ESCResolver


var _interpreter
var _compiler
var _scopes: Array = []


func _init(interpreter) -> void:
	_interpreter = interpreter


func resolve(statements):
	if not statements is Array:
		statements = [statements]

	var ret = null

	for stmt in statements:
		ret = _resolve_stmt(stmt)

		# TODO: Error handling?


func visit_event_stmt(stmt: ESCGrammarStmts.Event):
	resolve(stmt.get_body())


func visit_block_stmt(stmt: ESCGrammarStmts.Block):
	_begin_scope()

	resolve(stmt.get_statements())

	_end_scope()


func visit_expression_stmt(stmt: ESCGrammarStmts.ESCExpression):
	_resolve_expr(stmt.get_expression())


func visit_if_stmt(stmt: ESCGrammarStmts.If):
	_resolve_expr(stmt.get_condition())
	_resolve_stmt(stmt.get_then_branch())

	for branch in stmt.get_elif_branches():
		_resolve_expr(branch.get_condition())
		_resolve_stmt(branch.get_then_branch())

	if stmt.get_else_branch():
		_resolve_stmt(stmt.get_else_branch())


func visit_while_stmt(stmt: ESCGrammarStmts.While):
	_resolve_expr(stmt.get_condition())
	_resolve_stmt(stmt.get_body())


func visit_pass_stmt(stmt: ESCGrammarStmts.Pass):
	pass


func visit_stop_stmt(stmt: ESCGrammarStmts.Stop):
	pass


func visit_var_stmt(stmt: ESCGrammarStmts.Var):
	_declare(stmt.get_name())

	if stmt.get_initializer():
		_resolve_expr(stmt.get_initializer())

	_define(stmt.get_name())


func visit_global_stmt(stmt: ESCGrammarStmts.Global):
	pass


func visit_dialog_option_stmt(stmt: ESCGrammarStmts.DialogOption):
	_resolve_expr(stmt.get_option())

	if stmt.get_condition():
		_resolve_expr(stmt.get_condition())

	_resolve_stmt(stmt.get_body())


func visit_break_stmt(stmt: ESCGrammarStmts.Break):
	if stmt.get_levels():
		_resolve_expr(stmt.get_levels())


func visit_done_stmt(stmt: ESCGrammarStmts.Done):
	pass


func visit_dialog_stmt(stmt: ESCGrammarStmts.Dialog):
	for arg in stmt.get_args():
		_resolve_expr(arg)

	resolve(stmt.get_options())


func visit_literal_expr(expr: ESCGrammarExprs.Literal):
	pass


func visit_call_expr(expr: ESCGrammarExprs.Call):
	_resolve_expr(expr.get_callee())

	for arg in expr.get_arguments():
		_resolve_expr(arg)


func visit_assign_expr(expr: ESCGrammarExprs.Assign):
	_resolve_expr(expr.get_value())
	_resolve_local(expr, expr.get_name())


func visit_in_inventory_expr(expr: ESCGrammarExprs.InInventory):
	_resolve_expr(expr.get_identifier())


func visit_is_expr(expr: ESCGrammarExprs.Is):
	_resolve_expr(expr.get_identifier())

	if expr.get_state():
		_resolve_expr(expr.get_state())


func visit_binary_expr(expr: ESCGrammarExprs.Binary):
	_resolve_expr(expr.get_left())
	_resolve_expr(expr.get_right())


func visit_logical_expr(expr: ESCGrammarExprs.Logical):
	_resolve_expr(expr.get_left())
	_resolve_expr(expr.get_right())


func visit_get_expr(expr: ESCGrammarExprs.Get):
	_resolve_expr(expr.get_object())


func visit_set_expr(expr: ESCGrammarExprs.Set):
	_resolve_expr(expr.get_object())
	_resolve_expr(expr.get_value())


func visit_grouping_expr(expr: ESCGrammarExprs.Grouping):
	_resolve_expr(expr.get_expression())


func visit_unary_expr(expr: ESCGrammarExprs.Unary):
	_resolve_expr(expr.get_right())


func visit_variable_expr(expr: ESCGrammarExprs.Variable):
	# If this is an ESCObject reference, we don't need to resolve it as we deal
	# with this when interpreting, similar to a global.
	if expr.get_name().get_lexeme().begins_with("$"):
		return

	if not _scopes.empty() \
		and _scopes.front().has(expr.get_name().get_lexeme()) \
		and not _scopes.front()[expr.get_name().get_lexeme()]:

		escoria.logger.error(
			self,
			"Can't read local variable in own initializer."
		)

	var resolved: bool = _resolve_local(expr, expr.get_name())

	#if not resolved:
	#	_interpreter.look_up_variable(expr.get_name(), expr)


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


func _resolve_local(expr: ESCGrammarExpr, name: ESCToken) -> bool:
	for i in range(0, _scopes.size()):
		if _scopes[i].has(name.get_lexeme()):
			_interpreter.resolve(expr, i)
			return true

	return false

