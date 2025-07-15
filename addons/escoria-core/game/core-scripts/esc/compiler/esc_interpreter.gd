extends RefCounted
class_name ESCInterpreter


const CURRENT_PLAYER_KEYWORD = "CURRENT_PLAYER"
const CURRENT_OBJECT = "THIS"


var _globals: ESCEnvironment
var _environment: ESCEnvironment = _globals

var _locals: Dictionary = {}

# The interpreter largely doesn't need to track state; however, for interruptions,
# we need a way to know which event a command is running for. This tracking is
# minimal and contained within the interpreter itself.
#
# Because yielding for a coroutine stores the current call stack and its state,
# if _current_event changes (e.g. some other event is being interpreted), resuming
# should remember the appropriate _current_event. In the case of a non-yielding
# command, the flow is synchronous, and so it isn't possible for _current_event
# to be changed and thus affect interruption.
#
# Still, this should be tested extensively, and, if at all possible, with multiple
# concurrent events running.
var _current_event: ESCGrammarStmts.Event

# While most of the time we only run a single event at a time, it is possible for
# multiple events to
var _event_stack: Array = []

var _builtin_functions: Array = [
	"print"
]


func _init(callables: Array, globals: Dictionary):
	_globals = ESCEnvironment.new()

	for callable in callables:
		_globals.define(callable.get_command_name(), callable)

	for key in globals.keys():
		_globals.define(key, globals[key])

	if not Engine.is_editor_hint():
		escoria.globals_manager.global_changed.connect(_on_global_changed)


func cleanup() -> void:
	if is_instance_valid(_globals):
		_globals.cleanup()
		_globals = null

	if is_instance_valid(_environment):
		_environment.cleanup()
		_environment = null

	_locals.clear()

	_current_event = null


func get_global_values() -> Dictionary:
	return _globals.get_values()


func reset() -> void:
	_locals = {}


func interrupt() -> void:
	if _current_event and _current_event.get_running_command():
		_current_event.interrupt()


func interpret(statements):
	if not statements is Array:
		statements = [statements]

	var rc = 0

	for stmt in statements:
		rc = await _execute(stmt)

		if rc is ESCParseError:
			# TODO: runtime error handling
			pass

	return rc


# Visitor implementations
func visit_block_stmt(stmt: ESCGrammarStmts.Block):
	var env: ESCEnvironment = ESCEnvironment.new()
	env.init(_environment)

	return await _execute_block(stmt.get_statements(), env)


func visit_event_stmt(stmt: ESCGrammarStmts.Event):
	_current_event = stmt

	stmt.reset_interrupt()

	escoria.logger.debug(
		self,
		"Event %s started." % stmt.get_event_name()
	)

	# TODO: Handle interrupts.
	var rc = await _execute(stmt.get_body())
	escoria.logger.debug(
		self,
		"Event (%s) was completed." % stmt.get_event_name()
	)

	_current_event = null

	# For now, we don't always return a return code from an event (e.g. when
	# a 'done' statement is issued, since we don't have a good way to tell when
	# we're at the top of a coroutine stack)
	if typeof(rc) != TYPE_INT:
		rc = ESCExecution.RC_OK

	if stmt.is_interrupted():
		rc = ESCExecution.RC_INTERRUPTED

	stmt.emit_finished(rc if rc else ESCExecution.RC_OK)
	#var event: ESCEvent = ESCEvent.new("")
	#event.init(stmt.get_name().get_lexeme(), stmt.get_flags())

	#var statements = []

	#for statement in stmt.get_statements():
	#	statements.append(_execute(statement))

	#event.statements = statements

	#return event


func visit_expression_stmt(stmt: ESCGrammarStmts.ESCExpression):
	return await _evaluate(stmt.get_expression())


func visit_call_expr(expr: ESCGrammarExprs.Call):
	var callee = await _evaluate(expr.get_callee())

	var args: Array = []

	for arg in expr.get_arguments():
		arg = await _evaluate(arg)

		# "Adapter" for current ESC commands since they don't currently take
		# ESCObject's (or ESCRoom's) as arguments.
		if arg is ESCObject or arg is ESCRoom:
			arg = arg.global_id

		args.append(arg)

	# if we don't have a command to run, check against any built-in functions and,
	# if one is found and is executed, we're done
	if not callee is ESCBaseCommand:
		if not callee in _builtin_functions:
			escoria.logger.error(
				self,
				"Can only call valid commands."
			)
		else:
			return _handle_builtin_function(callee, args)

	var command = ESCCommand.new()
	command.parameters = args
	command.name = callee.get_command_name()
	command.parser_token = expr.get_paren_token()

	var rc = ESCExecution.RC_OK

	if command.is_valid() and not _current_event.is_interrupted():
		_current_event.set_running_command(command)
		rc = await command.run()
		escoria.logger.debug(
			self,
			"Statement (%s) was completed." % command
		)

		_current_event.clear_running_command()

	return rc


# TODO: If we end up having functions that need to return values, use and 'out' parameter.
func _handle_builtin_function(fn_name: String, args: Array) -> int:
	var rc = ESCExecution.RC_ERROR

	match fn_name:
		'print':
			if args.size() > 1:
				escoria.logger.error(
					self,
					"'print' only takes one argument"
				)

			_print(args)
			rc = ESCExecution.RC_OK

	return rc


func _print(value):
	if value[0] == null:
		value[0] = "nil"

	print(value[0])


func visit_if_stmt(stmt: ESCGrammarStmts.If):
	if _is_truthy(await _evaluate(stmt.get_condition())):
		return await _execute(stmt.get_then_branch())
	else:
		#var branched: bool = false

		for branch in stmt.get_elif_branches():
			if _is_truthy(await _evaluate(branch.get_condition())):
				return await _execute(branch)
#				branched = true
#				break

		#if not branched and stmt.get_else_branch():
		if stmt.get_else_branch():
			return await _execute(stmt.get_else_branch())

	return null


func visit_while_stmt(stmt: ESCGrammarStmts.While):
	while _is_truthy(await _evaluate(stmt.get_condition())):
		var ret = await _execute(stmt.get_body())

		if ret is ESCGrammarStmts.Break:
			break

	return null


func visit_pass_stmt(stmt: ESCGrammarStmts.Pass):
	pass


func visit_stop_stmt(stmt: ESCGrammarStmts.Stop):
	return stmt


func visit_var_stmt(stmt: ESCGrammarStmts.Var):
	var value = null

	if stmt.get_initializer():
		value = await _evaluate(stmt.get_initializer())

	_environment.define(stmt.get_name().get_lexeme(), value)
	return null


func visit_global_stmt(stmt: ESCGrammarStmts.Global):
	var value = null

	if stmt.get_initializer():
		value = await _evaluate(stmt.get_initializer())

	# Only define the global if we haven't already done so; otherwise, just
	# ignore it
	if not _globals.get_values().has(stmt.get_name().get_lexeme()):
		_globals.define(stmt.get_name().get_lexeme(), value)

	return null


func visit_dialog_stmt(stmt: ESCGrammarStmts.Dialog):
	var dialog: ESCDialog = ESCDialog.new()
	var rc = ESCExecution.RC_OK

	while true:
		dialog.options = []

		for dialog_option in stmt.get_options():
			var option: ESCDialogOption = ESCDialogOption.new()
			# TODO: Translation keys
			option.source_option = dialog_option
			option.option = await _evaluate(dialog_option.get_option())

			if dialog_option.get_condition():
				option.set_is_valid(await _evaluate(dialog_option.get_condition()))
			else:
				option.set_is_valid(true)

			dialog.options.append(option)

		if dialog.options.size() == 0:
			break

		if dialog.is_valid() and not _current_event.is_interrupted():
			#_current_event.set_running_command(dialog)
			#rc = dialog.run()
			var chosen_option = await dialog.run()

			if chosen_option:
				var execute_ret = await _execute(chosen_option.source_option.get_body())
				escoria.logger.debug(
					self,
					"Chosen dialog option (%s) was completed." % chosen_option
				)

				if execute_ret is ESCGrammarStmts.Break:
					var break_tracker: ESCBreakCounter = ESCBreakCounter.new()

					if execute_ret.get_levels():
						break_tracker.set_levels_left(await _evaluate(execute_ret.get_levels()) - 1)
					else:
						break_tracker.set_levels_left(0)

					return break_tracker
				elif execute_ret is ESCGrammarStmts.Done:
					return execute_ret
				elif execute_ret is ESCBreakCounter:
					if execute_ret.get_levels_left() > 0:
						execute_ret.dec_levels_left()
						return execute_ret

#		if rc is GDScriptFunctionState:
#			rc = yield(rc, "completed")
#			escoria.logger.debug(
#				self,
#				"Dialog (%s) was completed." % dialog
#			)

		#_current_event.clear_running_command()

	return rc


func visit_dialog_option_stmt(stmt: ESCGrammarStmts.DialogOption):
	pass


func visit_break_stmt(stmt: ESCGrammarStmts.Break):
	return stmt


func visit_done_stmt(stmt: ESCGrammarStmts.Done):
	return stmt


func visit_assign_expr(expr: ESCGrammarExprs.Assign):
	var value = await _evaluate(expr.get_value())

	var distance: int = _locals.get(expr, -1)

	if distance == -1:
		_globals.assign(expr.get_name(), value)
		escoria.globals_manager.set_global(expr.get_name().get_lexeme(), value)
	else:
		_environment.assign_at(distance, expr.get_name(), value)

	return value


func visit_in_inventory_expr(expr: ESCGrammarExprs.InInventory):
	var arg = await _evaluate(expr.get_identifier())

	if arg is ESCObject:
		arg = arg.global_id

	return escoria.inventory_manager.inventory_has(arg)


func visit_is_expr(expr: ESCGrammarExprs.Is):
	var arg = await _evaluate(expr.get_identifier())

	if typeof(arg) == TYPE_STRING:
		if escoria.inventory_manager.inventory_has(arg):
			arg = _look_up_object_by_global_id(arg)

	if expr.get_state():
		return arg.get_state() == await _evaluate(expr.get_state())

	return arg.is_active()


func visit_binary_expr(expr: ESCGrammarExprs.Binary):
	var left_part = await _evaluate(expr.get_left())
	var right_part = await _evaluate(expr.get_right())

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

			escoria.logger.error(
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
	var right_part = await _evaluate(expr.get_right())

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
	var left = await _evaluate(expr.get_left())

	if expr.get_operator().get_type() == ESCTokenType.TokenType.OR:
		if _is_truthy(left):
			return left
	else:
		if not _is_truthy(left):
			return left

	return await _evaluate(expr.get_right())


func visit_grouping_expr(expr: ESCGrammarExprs.Grouping):
	return await _evaluate(expr.get_expression())


func resolve(expr: ESCGrammarExpr, depth: int):
	_locals[expr] = depth


# Private methods
func _look_up_object(name: ESCToken):
	var global_id: String = name.get_lexeme().substr(1)

	if global_id.to_upper() == CURRENT_PLAYER_KEYWORD:
		global_id = escoria.main.current_scene.player.global_id
	elif global_id.to_upper() == CURRENT_OBJECT:
		# check if the event is attached to an object; if it isn't, then
		# assume it's associated to the current scene (room)
		global_id = _current_event.get_object_global_id()

		if global_id.is_empty():
			global_id = escoria.main.current_scene.global_id

	return _look_up_object_by_global_id(global_id)


func _look_up_object_by_global_id(global_id: String):
	var obj = escoria.object_manager.get_object(global_id) # ESCObject

	if obj:
		return obj

	if escoria.main.current_scene.global_id == global_id:
		return escoria.main.current_scene

	escoria.logger.error(
		self,
		"Unable to resolve object with global ID '%s'." % global_id
	)

	return null


func look_up_variable(name: ESCToken, expr: ESCGrammarExpr):
	var distance: int = _locals[expr] if _locals.has(expr) else -1

	if distance == -1:
		return _globals.get_value(name)
	else:
		return _environment.get_at(distance, name.get_lexeme())


func look_up_global(name: ESCToken):
	if _globals.get_values().has(name.get_lexeme()):
		return _globals.get_value(name)

	return null


func _evaluate(expr: ESCGrammarExpr):
	var ret = await expr.accept(self)

	# TODO: Error handling
	return ret


func _execute(stmt: ESCGrammarStmt):
	var ret = await stmt.accept(self)

	# TODO: Error handling
	return ret


func _execute_block(statements: Array, env: ESCEnvironment):
	var previous_env = _environment
	var ret = null

	_environment = env

	for stmt in statements:
		ret = await _execute(stmt)

		if ret is ESCGrammarStmts.Break \
			or ret is ESCGrammarStmts.Done \
			or ret is ESCGrammarStmts.Stop:

			return ret

		# TODO: Proper error handling per statement?
		#if ret:
		#	break

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
		escoria.logger.error(
			self,
			"%s: Operands must be numbers." % operator.get_lexeme()
		)

	return false


func _check_is_number(value, operator: ESCToken, strict: bool = true):
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		return true

	if strict:
		escoria.logger.error(
			self,
			"%s: Operand must be number." % operator.get_lexeme()
		)

	return false


func _check_at_least_one_string(value_1, value_2):
	return typeof(value_1) == TYPE_STRING || typeof(value_2) == TYPE_STRING


func _on_global_changed(key: String, old_value, new_value) -> void:
	# Shoehorn this in as an adapter
	var token: ESCToken = ESCToken.new()
	token.init(ESCTokenType.TokenType.IDENTIFIER, key, null, "", -1, "")

	if _globals.get_values().has(key):
		_globals.assign(token, new_value)
	elif escoria.save_manager.is_loading_game:
		_globals.define(key, new_value)
