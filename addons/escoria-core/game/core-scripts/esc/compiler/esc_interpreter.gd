extends Reference
class_name ESCInterpreter


const CURRENT_PLAYER_KEYWORD = "CURRENT_PLAYER"


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


func _init(callables: Array, globals: Dictionary):
	_globals = ESCEnvironment.new()

	for callable in callables:
		_globals.define(callable.get_command_name(), callable)

	for key in globals.keys():
		_globals.define(key, globals[key])


func reset() -> void:
	_locals = {}


func interrupt() -> void:
	if _current_event and _current_event.get_running_command():
		_current_event.interrupt_running_command()


func interpret(statements):
	if not statements is Array:
		statements = [statements]

	var rc = 0

	for stmt in statements:
		rc = _execute(stmt)

		if rc is ESCParseError:
			# TODO: runtime error handling
			pass

	return rc


# Visitor implementations
func visit_block_stmt(stmt: ESCGrammarStmts.Block):
	var env: ESCEnvironment = ESCEnvironment.new()
	env.init(_environment)

	return _execute_block(stmt.get_statements(), env)


func visit_event_stmt(stmt: ESCGrammarStmts.Event):
	_current_event = stmt

	stmt.reset_interrupt()

	escoria.logger.debug(
		self,
		"Event %s started." % stmt.get_event_name()
	)

	# TODO: Handle interrupts.
	var rc = _execute(stmt.get_body())

	if rc is GDScriptFunctionState:
		rc = yield(rc, "completed")
		escoria.logger.debug(
			self,
			"Event (%s) was completed." % stmt.get_event_name()
		)
#	if rc == ESCExecution.RC_REPEAT:
#		return self.run()
#	elif rc != ESCExecution.RC_OK:
#		final_rc = rc

	_current_event = null

	# For now, we don't always return a return code from an event (e.g. when
	# a 'done' statement is issued, since we don't have a good way to tell when
	# we're at the top of a coroutine stack)
	if typeof(rc) != TYPE_INT:
		rc = ESCExecution.RC_OK

	stmt.emit_finished(rc if rc else ESCExecution.RC_OK)
	#var event: ESCEvent = ESCEvent.new("")
	#event.init(stmt.get_name().get_lexeme(), stmt.get_flags())

	#var statements = []

	#for statement in stmt.get_statements():
	#	statements.append(_execute(statement))
	
	#event.statements = statements
	
	#return event


func visit_expression_stmt(stmt: ESCGrammarStmts.ESCExpression):
	return _evaluate(stmt.get_expression())


func visit_call_expr(expr: ESCGrammarExprs.Call):
	var callee = _evaluate(expr.get_callee())

	if not callee is ESCBaseCommand:
		escoria.logger.error(
			self,
			"Can only call valid commands."
		)

	var args: Array = []

	for arg in expr.get_arguments():
		arg = _evaluate(arg)

		# "Adapter" for current ESC commands since they don't currently take
		# ESCObjects as arguments.
		if arg is ESCObject:
			arg = arg.global_id

		args.append(arg)

	var command = ESCCommand.new()
	command.parameters = args
	command.name = callee.get_command_name()

	var rc = ESCExecution.RC_OK

	if command.is_valid() and not _current_event.is_interrupted():
		_current_event.set_running_command(command)
		rc = command.run()

		if rc is GDScriptFunctionState:
			rc = yield(rc, "completed")
			escoria.logger.debug(
				self,
				"Statement (%s) was completed." % command
			)

		_current_event.clear_running_command()

#		if rc == ESCExecution.RC_REPEAT:
#			return self.run()
#		elif rc != ESCExecution.RC_OK:
#			final_rc = rc

	return rc


func visit_if_stmt(stmt: ESCGrammarStmts.If):
	if _is_truthy(_evaluate(stmt.get_condition())):
		return _execute(stmt.get_then_branch())
	else:
		#var branched: bool = false

		for branch in stmt.get_elif_branches():
			if _is_truthy(_evaluate(branch.get_condition())):
				return _execute(branch)
#				branched = true
#				break

		#if not branched and stmt.get_else_branch():
		if stmt.get_else_branch():
			return _execute(stmt.get_else_branch())

	return null


func visit_print_stmt(stmt: ESCGrammarStmts.Print):
	var value = _evaluate(stmt.get_expression())

	if value == null:
		value = "nil"

	print(value)

	return null


func visit_while_stmt(stmt: ESCGrammarStmts.While):
	while _is_truthy(_evaluate(stmt.get_condition())):
		var ret = _execute(stmt.get_body())

		if ret is GDScriptFunctionState:
			ret = yield(ret, "completed")

		if ret is ESCGrammarStmts.Break:
			break

	return null


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
			option.option = _evaluate(dialog_option.get_option())

			if dialog_option.get_condition():
				option.set_is_valid(_evaluate(dialog_option.get_condition()))
			else:
				option.set_is_valid(true)

			dialog.options.append(option)

		if dialog.options.size() == 0:
			break

		if dialog.is_valid() and not _current_event.is_interrupted():
			#_current_event.set_running_command(dialog)
			#rc = dialog.run()
			var chosen_option = dialog.run()

			if chosen_option is GDScriptFunctionState:
				chosen_option = yield(chosen_option, "completed")

			if chosen_option:
				var execute_ret = _execute(chosen_option.source_option.get_body())

				if execute_ret is GDScriptFunctionState:
					execute_ret = yield(execute_ret, "completed")
					escoria.logger.debug(
						self,
						"Chosen dialog option (%s) was completed." % chosen_option
					)

				if execute_ret is ESCGrammarStmts.Break:
					var break_tracker: ESCBreakCounter = ESCBreakCounter.new()

					if execute_ret.get_levels():
						break_tracker.set_levels_left(_evaluate(execute_ret.get_levels()) - 1)
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
	var value = _evaluate(expr.get_value())

	var distance: int = _locals.get(expr, -1)

	if distance == -1:
		_globals.assign(expr.get_name(), value)
	else:
		_environment.assign_at(distance, expr.get_name(), value)

	return value


func visit_in_inventory_expr(expr: ESCGrammarExprs.InInventory):
	var arg = _evaluate(expr.get_identifier())

	if arg is ESCObject:
		arg = arg.global_id

	return escoria.inventory_manager.inventory_has(arg)


func visit_is_expr(expr: ESCGrammarExprs.Is):
	var arg = _evaluate(expr.get_identifier())

	if typeof(arg) == TYPE_STRING:
		if escoria.inventory_manager.inventory_has(arg):
			arg = _look_up_object_by_global_id(arg)

	if expr.get_state():
		return arg.get_state() == _evaluate(expr.get_state())

	return arg.is_active()


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

	return _look_up_variable(expr.get_name(), expr)


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
		global_id = escoria.main.current_scene.player.global_id

	return _look_up_object_by_global_id(global_id)


func _look_up_object_by_global_id(global_id: String):
	var obj: ESCObject = escoria.object_manager.get_object(global_id)

	if not obj:
		escoria.logger.error(
			self,
			"Unable to resolve object with global ID '%s'." % global_id
		)

	return obj


func _look_up_variable(name: ESCToken, expr: ESCGrammarExpr):
	var distance: int = _locals[expr] if _locals.has(expr) else -1

	if distance == -1:
		return _globals.get_value(name)
	else:
		return _environment.get_at(distance, name.get_lexeme())


func _evaluate(expr: ESCGrammarExpr):
	var ret = expr.accept(self)

	if ret is GDScriptFunctionState:
		ret = yield(ret, "completed")

	# TODO: Error handling
	return ret


func _execute(stmt: ESCGrammarStmt):
	var ret = stmt.accept(self)

	if ret is GDScriptFunctionState:
		ret = yield(ret, "completed")

	# TODO: Error handling
	return ret


func _execute_block(statements: Array, env: ESCEnvironment):
	var previous_env = _environment
	var ret = null

	_environment = env

	for stmt in statements:
		ret = _execute(stmt)

		if ret is GDScriptFunctionState:
			ret = yield(ret, "completed")

		if ret is ESCGrammarStmts.Break \
			or ret is ESCGrammarStmts.Done:

			return ret

		# TODO: Proper error handling per statement?
		#if ret:
		#	break

	_environment = previous_env

	return ret


func _is_truthy(value) -> bool:
	if value == null:
		return false

	return value == true


func _is_equal(left_part, right_part) -> bool:
	if not left_part and not right_part:
		return true

	if not left_part:
		return false

	return left_part == right_part


func _check_are_numbers(value_1, operator: ESCToken, value_2, strict: bool = true):
	if typeof(value_1) in [TYPE_INT, TYPE_REAL] and typeof(value_2) in [TYPE_INT, TYPE_REAL]:
		return true

	if strict:
		escoria.logger.error(
			self,
			"%s: Operands must be numbers." % operator.get_lexeme()
		)

	return false


func _check_is_number(value, operator: ESCToken, strict: bool = true):
	if typeof(value) in [TYPE_INT, TYPE_REAL]:
		return true

	if strict:
		escoria.logger.error(
			self,
			"%s: Operand must be number." % operator.get_lexeme()
		)

	return false

func _check_at_least_one_string(value_1, value_2):
	return typeof(value_1) == TYPE_STRING || typeof(value_2) == TYPE_STRING
