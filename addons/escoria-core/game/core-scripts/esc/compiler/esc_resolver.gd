## Resolves script variables to ensure that scoping rules are obeyed.
##
## The class will throw errors if scoping rules are broken or otherwise not followed.
extends RefCounted
class_name ESCResolver


var _interpreter
var _compiler
var _scopes: Array = []


func _init(interpreter) -> void:
	_interpreter = interpreter


## Entry point for the resolver. Begins attempting to resolve one or more statements 
## passed in.[br]
##[br]
## #### Parameters ####[br]
## - *statements*: a single `ESCGrammarStmt`-derived statement or an array of them, 
## representing the statements to be resolved
func resolve(statements):
	if not statements is Array:
		statements = [statements]

	var ret = null

	for stmt in statements:
		ret = _resolve_stmt(stmt)

		# TODO: Error handling?


## Attempts to resolve an Escoria event, e.g. `:look`.
func visit_event_stmt(stmt: ESCGrammarStmts.Event):
	resolve(stmt.get_body())


## Attempts to resolve a block statement.
func visit_block_stmt(stmt: ESCGrammarStmts.Block):
	_begin_scope()

	resolve(stmt.get_statements())

	_end_scope()


## Attempts to resolve an expression contained in a statement.
func visit_expression_stmt(stmt: ESCGrammarStmts.ESCExpression):
	_resolve_expr(stmt.get_expression())


## Attempts to resolve the various parts of an `if` statement, i.e. 
## the predicates and related branches.
func visit_if_stmt(stmt: ESCGrammarStmts.If):
	_resolve_expr(stmt.get_condition())
	_resolve_stmt(stmt.get_then_branch())

	for branch in stmt.get_elif_branches():
		_resolve_expr(branch.get_condition())
		_resolve_stmt(branch.get_then_branch())

	if stmt.get_else_branch():
		_resolve_stmt(stmt.get_else_branch())


## Attempts to resolve the predicate of a `while` loop along with the loop body.
func visit_while_stmt(stmt: ESCGrammarStmts.While):
	_resolve_expr(stmt.get_condition())
	_resolve_stmt(stmt.get_body())


## `pass` statements contain nothing to resolve, so are skipped over.
func visit_pass_stmt(stmt: ESCGrammarStmts.Pass):
	pass


## `stop` statements contain nothing to resolve, so are skipped over.
func visit_stop_stmt(stmt: ESCGrammarStmts.Stop):
	pass


## Attempts to resolve a variable declaration statement along with its possible 
## initializer.
func visit_var_stmt(stmt: ESCGrammarStmts.Var):
	_declare(stmt.get_name())

	if stmt.get_initializer():
		_resolve_expr(stmt.get_initializer())

	_define(stmt.get_name())


## `global` statements are available at all scoping levels and so require no resolution.
func visit_global_stmt(stmt: ESCGrammarStmts.Global):
	pass


## Attempts to resolve the various parts of a dialog option, i.e. the option expression, 
## the condition (if one exists), and the body of the option.
func visit_dialog_option_stmt(stmt: ESCGrammarStmts.DialogOption):
	_resolve_expr(stmt.get_option())

	if stmt.get_condition():
		_resolve_expr(stmt.get_condition())

	_resolve_stmt(stmt.get_body())


## Attempts to resolve a `break` statement if used inside a dialog.
func visit_break_stmt(stmt: ESCGrammarStmts.Break):
	if stmt.get_levels():
		_resolve_expr(stmt.get_levels())


## `done` statements contain nothing to resolve, so are skipped over.
func visit_done_stmt(stmt: ESCGrammarStmts.Done):
	pass


## Attempts to resolve a dialog's arguments and options.
func visit_dialog_stmt(stmt: ESCGrammarStmts.Dialog):
	for arg in stmt.get_args():
		_resolve_expr(arg)

	resolve(stmt.get_options())


## Literals contain nothing to resolve, so are skipped over.
func visit_literal_expr(expr: ESCGrammarExprs.Literal):
	pass


## Attempts to resolve a function/method call expression, including its name 
## and arguments.
func visit_call_expr(expr: ESCGrammarExprs.Call):
	_resolve_expr(expr.get_callee())

	for arg in expr.get_arguments():
		_resolve_expr(arg)


## Attempts to resolve an assignment expression.
func visit_assign_expr(expr: ESCGrammarExprs.Assign):
	_resolve_expr(expr.get_value())
	_resolve_local(expr, expr.get_name())


## Attempts to resolve an `in` expression, specifically the item identifier.
func visit_in_inventory_expr(expr: ESCGrammarExprs.InInventory):
	_resolve_expr(expr.get_identifier())


## Attempts to resolve an `is` expression, including the item identifier and the 
## state (if one is specified).
func visit_is_expr(expr: ESCGrammarExprs.Is):
	_resolve_expr(expr.get_identifier())

	if expr.get_state():
		_resolve_expr(expr.get_state())


## Attempts to resolve a binary expression.
func visit_binary_expr(expr: ESCGrammarExprs.Binary):
	_resolve_expr(expr.get_left())
	_resolve_expr(expr.get_right())


## Attempts to resolve a logical expression.
func visit_logical_expr(expr: ESCGrammarExprs.Logical):
	_resolve_expr(expr.get_left())
	_resolve_expr(expr.get_right())


## Attempts to resolve a `get` expression (possibly not used at the moment).
func visit_get_expr(expr: ESCGrammarExprs.Get):
	_resolve_expr(expr.get_object())


## Attempts to resolve a `set` expression (possibly not used at the moment).
func visit_set_expr(expr: ESCGrammarExprs.Set):
	_resolve_expr(expr.get_object())
	_resolve_expr(expr.get_value())


## Attempts to resolve a grouping expression.
func visit_grouping_expr(expr: ESCGrammarExprs.Grouping):
	_resolve_expr(expr.get_expression())


## Attempts to resolve a unary expression.
func visit_unary_expr(expr: ESCGrammarExprs.Unary):
	_resolve_expr(expr.get_right())


## Attempts to resolve a local variable expression
func visit_variable_expr(expr: ESCGrammarExprs.Variable):
	# If this is an ESCObject reference, we don't need to resolve it as we deal
	# with this when interpreting, similar to a global.
	if expr.get_name().get_lexeme().begins_with("$"):
		return

	if not _scopes.is_empty() \
		and _scopes.front().has(expr.get_name().get_lexeme()) \
		and not _scopes.front()[expr.get_name().get_lexeme()]:

		ESCSafeLogging.log_error(self, "Can't read local variable in own initializer.")

	var resolved: bool = _resolve_local(expr, expr.get_name())


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
	if _scopes.is_empty():
		return

	var scope: Dictionary = _scopes.front()

	if scope.has(name.get_lexeme()):
		# TODO: Better error handling
		ESCSafeLogging.log_error(self, "Already a variable with name '%s' in this scope." % name.get_lexeme())

	scope[name.get_lexeme()] = false


func _define(name: ESCToken):
	if _scopes.is_empty():
		return

	_scopes.front()[name.get_lexeme()] = true


func _resolve_local(expr: ESCGrammarExpr, name: ESCToken) -> bool:
	for i in range(0, _scopes.size()):
		if _scopes[i].has(name.get_lexeme()):
			_interpreter.resolve(expr, i)
			return true

	return false
