extends RefCounted
class_name ESCScriptAnalyzer


const CURRENT_PLAYER_KEYWORD = "CURRENT_PLAYER"


var _rich_messages: Array[Callable] = []

var _globals: ESCEnvironment
var _environment: ESCEnvironment = _globals

var _locals: Dictionary = {}

var _builtin_functions: Array = [
	"print"
]


# This must be implemented in child class.
func analyze(statements: Array) -> void:
	pass


func print_messages() -> void:
	for print_method in _rich_messages:
		print_method.call()


func _init():
	var globals: Dictionary = ESCCompiler.load_globals()

	_globals = ESCEnvironment.new()

	for callable in ESCCompiler.load_commands():
		_globals.define(callable.get_command_name(), callable)

	for key in ESCCompiler.load_globals().keys():
		_globals.define(key, globals[key])


# Visitor implementations
func visit_block_stmt(stmt: ESCGrammarStmts.Block):
	var env: ESCEnvironment = ESCEnvironment.new()
	env.init(_environment)

	return _execute_block(stmt.get_statements(), env)


func visit_event_stmt(stmt: ESCGrammarStmts.Event):
	_execute(stmt.get_body())


func visit_expression_stmt(stmt: ESCGrammarStmts.ESCExpression):
	return _evaluate(stmt.get_expression())


func visit_call_expr(expr: ESCGrammarExprs.Call):
	var callee = _evaluate(expr.get_callee())

	var args: Array = []

	for arg in expr.get_arguments():
		arg = _evaluate(arg)

		# "Adapter" for current ESC commands since they don't currently take
		# ESCObject's (or ESCRoom's) as arguments.
		if arg is ESCObject or arg is ESCRoom:
			arg = arg.global_id

		args.append(arg)

	# if we don't have a command to run, check against any built-in functions and,
	# if one is found and is executed, we're done
	if not callee is ESCBaseCommand:
		if not callee in _builtin_functions:
			return 0
		else:
			return _handle_builtin_function(callee, args)

	return ESCExecution.RC_OK


func _handle_builtin_function(fn_name: String, args: Array) -> int:
	var rc = ESCExecution.RC_ERROR

	match fn_name:
		'print':
			if args.size() > 1:
				ESCSafeLogging.log_warn(
					self,
					"'print' only takes one argument"
				)

			rc = ESCExecution.RC_OK

	return rc


func visit_if_stmt(stmt: ESCGrammarStmts.If):
	_execute(stmt.get_then_branch())

	for branch in stmt.get_elif_branches():
		_execute(branch)

	if stmt.get_else_branch():
		_execute(stmt.get_else_branch())

	return null


func visit_while_stmt(stmt: ESCGrammarStmts.While):
	_execute(stmt.get_body())

	return null


func visit_pass_stmt(stmt: ESCGrammarStmts.Pass):
	pass


func visit_stop_stmt(stmt: ESCGrammarStmts.Stop):
	return stmt


func visit_var_stmt(stmt: ESCGrammarStmts.Var):
	var value = null

	if stmt.get_initializer():
		value = _evaluate(stmt.get_initializer())

	_environment.define(stmt.get_name().get_lexeme(), value)
	return null


func visit_global_stmt(stmt: ESCGrammarStmts.Global):
	var value = null

	if stmt.get_initializer():
		value = _evaluate(stmt.get_initializer())

	# Only define the global if we haven't already done so; otherwise, just
	# ignore it
	if not _globals.get_values().has(stmt.get_name().get_lexeme()):
		_globals.define(stmt.get_name().get_lexeme(), value)

	return null


func visit_dialog_stmt(stmt: ESCGrammarStmts.Dialog):
	return null


func visit_dialog_option_stmt(stmt: ESCGrammarStmts.DialogOption):
	pass


func visit_break_stmt(stmt: ESCGrammarStmts.Break):
	return stmt


func visit_done_stmt(stmt: ESCGrammarStmts.Done):
	return stmt


func visit_assign_expr(expr: ESCGrammarExprs.Assign):
	var value = _evaluate(expr.get_value())

	var distance: int = _locals.get(expr, -1)

	return value


func visit_in_inventory_expr(expr: ESCGrammarExprs.InInventory):
	var arg = _evaluate(expr.get_identifier())

	if arg is ESCObject:
		arg = arg.global_id

	return null


func visit_is_expr(expr: ESCGrammarExprs.Is):
	var arg = _evaluate(expr.get_identifier())

	return true


func visit_binary_expr(expr: ESCGrammarExprs.Binary):
	var left_part = _evaluate(expr.get_left())
	var right_part = _evaluate(expr.get_right())

	match expr.get_operator().get_type():
		ESCTokenType.TokenType.EQUAL_EQUAL:
			return _is_equal(left_part, right_part)
		ESCTokenType.TokenType.BANG_EQUAL:
			return not _is_equal(left_part, right_part)
		ESCTokenType.TokenType.GREATER:
			var check = _check_are_numbers(left_part, expr.get_operator(), right_part)
			return left_part > right_part
		ESCTokenType.TokenType.GREATER_EQUAL:
			var check = _check_are_numbers(left_part, expr.get_operator(), right_part)
			return left_part >= right_part
		ESCTokenType.TokenType.LESS:
			var check = _check_are_numbers(left_part, expr.get_operator(), right_part)
			return left_part < right_part
		ESCTokenType.TokenType.LESS_EQUAL:
			var check = _check_are_numbers(left_part, expr.get_operator(), right_part)
			return left_part <= right_part
		ESCTokenType.TokenType.MINUS:
			var check = _check_are_numbers(left_part, expr.get_operator(), right_part)
			return left_part - right_part
		ESCTokenType.TokenType.PLUS:
			var check = _check_are_numbers(left_part, expr.get_operator(), right_part, false)

			if check:
				return left_part + right_part

			check = _check_at_least_one_string(left_part, right_part)

			if check:
				return str(left_part) + str(right_part)

			ESCSafeLogging.log_warn(
				self,
				"%s: Operands must be numbers or strings." % expr.get_operator().get_lexeme()
			)
		ESCTokenType.TokenType.SLASH:
			var check = _check_are_numbers(left_part, expr.get_operator(), right_part)
			return left_part / right_part
		ESCTokenType.TokenType.STAR:
			var check = _check_are_numbers(left_part, expr.get_operator(), right_part)
			return left_part * right_part

	return null


func visit_unary_expr(expr: ESCGrammarExprs.Unary):
	var right_part = _evaluate(expr.get_right())

	match expr.get_operator().get_type():
		ESCTokenType.TokenType.BANG, ESCTokenType.TokenType.NOT:
			return not _is_truthy(right_part)
		ESCTokenType.TokenType.MINUS:
			var check = _check_is_number(right_part, expr.get_operator())
			return -right_part

	return null


func visit_variable_expr(expr: ESCGrammarExprs.Variable):
	if expr.get_name().get_lexeme().begins_with("$"):
		return _look_up_object(expr.get_name())

	if expr.get_name().get_lexeme() in _builtin_functions:
		return expr.get_name().get_lexeme()

	return look_up_variable(expr.get_name(), expr)


func visit_literal_expr(expr: ESCGrammarExprs.Literal):
	return expr.get_value()


func visit_logical_expr(expr: ESCGrammarExprs.Logical):
	var left = _evaluate(expr.get_left())

	if expr.get_operator().get_type() == ESCTokenType.TokenType.OR:
		if _is_truthy(left):
			return left
	else:
		if not _is_truthy(left):
			return left

	return _evaluate(expr.get_right())


func visit_grouping_expr(expr: ESCGrammarExprs.Grouping):
	return _evaluate(expr.get_expression())


func resolve(expr: ESCGrammarExpr, depth: int):
	_locals[expr] = depth


# Private methods
func _look_up_object(name: ESCToken):
	var global_id: String = name.get_lexeme().substr(1)

	if global_id.to_upper() == CURRENT_PLAYER_KEYWORD:
		pass

	return _look_up_object_by_global_id(global_id)


# We have no way of knowing what the value will actually be since this is called during static
# analysis. As such, we'll just return null.
func _look_up_object_by_global_id(global_id: String):
	return null


# We don't care about the values of variables for static analysis purposes.
func look_up_variable(name: ESCToken, expr: ESCGrammarExpr):
	var distance: int = _locals[expr] if _locals.has(expr) else -1

	if distance == -1:
		return _globals.get_value(name)
	else:
		return _environment.get_at(distance, name.get_lexeme())


func _evaluate(expr: ESCGrammarExpr):
	var ret = expr.accept(self)

	# TODO: Error handling
	return ret


func _execute(stmt: ESCGrammarStmt):
	var ret = stmt.accept(self)

	# TODO: Error handling
	return ret


func _execute_block(statements: Array, env: ESCEnvironment):
	var previous_env = _environment
	var ret = null

	_environment = env

	for stmt in statements:
		ret = _execute(stmt)

	_environment = previous_env

	return ret


func _is_truthy(value) -> bool:
	if value == null:
		return false

	if typeof(value) in [TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_BOOL]:
		return bool(value) == true

	return false


func _is_equal(left_part, right_part) -> bool:
	if not left_part and not right_part:
		return true

	if not left_part:
		return false

	return left_part == right_part


func _check_are_numbers(value_1, operator: ESCToken, value_2, strict: bool = true):
	if typeof(value_1) in [TYPE_INT, TYPE_FLOAT] and typeof(value_2) in [TYPE_INT, TYPE_FLOAT]:
		return true

	if strict:
		ESCSafeLogging.log_warn(
			self,
			"%s: Operands must be numbers." % operator.get_lexeme()
		)

	return false


func _check_is_number(value, operator: ESCToken, strict: bool = true):
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		return true

	if strict:
		ESCSafeLogging.log_warn(
			self,
			"%s: Operand must be number." % operator.get_lexeme()
		)

	return false


func _check_at_least_one_string(value_1, value_2):
	return typeof(value_1) == TYPE_STRING || typeof(value_2) == TYPE_STRING
