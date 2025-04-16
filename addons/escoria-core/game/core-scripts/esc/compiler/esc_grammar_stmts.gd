class_name ESCGrammarStmts


class Var extends ESCGrammarStmt:
	var _name: ESCToken:
		get = get_name
	var _initializer: ESCGrammarExpr:
		get = get_initializer


	func init(name: ESCToken, initializer: ESCGrammarExpr):
		_name = name
		_initializer = initializer


	func get_name() -> ESCToken:
		return _name


	func get_initializer() -> ESCGrammarExpr:
		return _initializer


	func accept(visitor):
		return await visitor.visit_var_stmt(self)


class Global extends ESCGrammarStmt:
	var _name: ESCToken:
		get = get_name
	var _initializer: ESCGrammarExpr:
		get = get_initializer


	func init(name: ESCToken, initializer: ESCGrammarExpr):
		_name = name
		_initializer = initializer


	func get_name() -> ESCToken:
		return _name


	func get_initializer() -> ESCGrammarExpr:
		return _initializer


	func accept(visitor):
		return await visitor.visit_global_stmt(self)


class Event extends ESCGrammarStmt:
	signal finished
	signal interrupted

	var _name: ESCToken:
		get = get_name
	var _target: ESCGrammarExprs.Literal:
		get = get_target
	var _flags: int:
		get = get_flags
	var _flags_with_conditions: Dictionary = {}:
		get = get_flags_with_conditions
	var _body: ESCGrammarStmts.Block:
		get = get_body

	var _running_command:
		set = set_running_command,
		get = get_running_command

	# Indicates whether this event was interrupted.
	var _is_interrupted: bool = false:
		get = is_interrupted

	var source: String = "" # TODO: Make proper use of this


	# Valid event flags
	# * TK: stands for "telekinetic". It means the player won't walk over to
	#   the item to say the line.
	# * NO_TT: stands for "No tooltip". It hides the tooltip for the duration of
	#   the event. Probably not very useful, because events having multiple
	#   say commands in them are automatically hidden.
	# * NO_UI: stands for "No User Inteface". It hides the UI for the duration of
	#   the event. Useful when you want something to look like a cut scene but not
	#   disable input for skipping dialog.
	# * NO_SAVE: disables saving. Use this in cut scenes and anywhere a
	#   badly-timed autosave would leave your game in a messed-up state.
	enum {
		FLAG_TK = 1,
		FLAG_NO_TT = 2,
		FLAG_NO_UI = 4,
		FLAG_NO_SAVE = 8
	}


	func init(name: ESCToken, target: ESCGrammarExprs.Literal, flags: Dictionary, body: ESCGrammarStmts.Block):
		_name = name
		_target = target

		for flag in flags.keys():
			match flag:
				"TK":
					_flags |= FLAG_TK
				"NO_TT":
					_flags |= FLAG_NO_TT
				"NO_UI":
					_flags |= FLAG_NO_UI
				"NO_SAVE":
					_flags |= FLAG_NO_SAVE

		_body = body
		_flags_with_conditions = flags


	func get_name() -> ESCToken:
		return _name


	func get_target() -> ESCGrammarExprs.Literal:
		return _target


	func get_target_name() -> String:
		return _target.get_value()


	func get_event_name() -> String:
		return _name.get_lexeme()


	func get_flags() -> int:
		return _flags


	func get_flags_with_conditions() -> Dictionary:
		return _flags_with_conditions


	func add_flag(flag: ESCEvent.FLAGS):
		_flags |= flag


	func get_body() -> ESCGrammarStmts.Block:
		return _body


	func get_num_statements_in_block() -> int:
		return _body.get_statements().size()


	func get_running_command():
		return _running_command


	func set_running_command(cmd) -> void:
		_running_command = cmd


	func clear_running_command() -> void:
		_running_command = null


	func interrupt() -> void:
		_is_interrupted = true

		if _running_command:
			_running_command.interrupt()


	func is_interrupted() -> bool:
		return _is_interrupted


	func reset_interrupt() -> void:
		_is_interrupted = false


	func emit_finished(rc: int):
		emit_signal("finished", self, null, rc)


	func accept(visitor):
		return await visitor.visit_event_stmt(self)


class Block extends ESCGrammarStmt:
	var _statements: Array:
		get = get_statements


	func init(statements: Array):
		_statements = statements


	func get_statements() -> Array:
		return _statements


	func accept(visitor):
		return await visitor.visit_block_stmt(self)


class ESCExpression extends ESCGrammarStmt:
	var _expression: ESCGrammarExpr:
		get = get_expression


	func init(expression: ESCGrammarExpr):
		_expression = expression


	func get_expression() -> ESCGrammarExpr:
		return _expression


	func accept(visitor):
		return await visitor.visit_expression_stmt(self)


class If extends ESCGrammarStmt:
	var _condition: ESCGrammarExpr:
		get = get_condition
	var _then_branch: ESCGrammarStmts.Block:
		get = get_then_branch
	var _elif_branches: Array:
		get = get_elif_branches
	var _else_branch: ESCGrammarStmts.Block:
		get = get_else_branch


	func init(condition: ESCGrammarExpr, then_branch: ESCGrammarStmts.Block, elif_branches: Array, else_branch: ESCGrammarStmts.Block):
		_condition = condition
		_then_branch = then_branch
		_elif_branches = elif_branches
		_else_branch = else_branch


	func get_condition() -> ESCGrammarExpr:
		return _condition


	func get_then_branch() -> ESCGrammarStmts.Block:
		return _then_branch


	func get_elif_branches() -> Array:
		return _elif_branches


	func get_else_branch() -> ESCGrammarStmts.Block:
		return _else_branch


	func accept(visitor):
		return await visitor.visit_if_stmt(self)


class While extends ESCGrammarStmt:
	var _condition: ESCGrammarExpr:
		get = get_condition
	var _body: ESCGrammarStmt:
		get = get_body


	func init(condition: ESCGrammarExpr, body: ESCGrammarStmt):
		_condition = condition
		_body = body


	func get_condition() -> ESCGrammarExpr:
		return _condition


	func get_body() -> ESCGrammarStmt:
		return _body


	func accept(visitor):
		return await visitor.visit_while_stmt(self)


class Pass extends ESCGrammarStmt:
	func accept(visitor):
		return await visitor.visit_pass_stmt(self)


class Stop extends ESCGrammarStmt:
	func accept(visitor):
		return await visitor.visit_stop_stmt(self)


class DialogOption extends ESCGrammarStmt:
	var _option: ESCGrammarExpr:
		get = get_option
	var _condition: ESCGrammarExpr:
		get = get_condition
	var _body: ESCGrammarStmt:
		get = get_body


	func init(option: ESCGrammarExpr, condition: ESCGrammarExpr, body: ESCGrammarStmt):
		_option = option
		_condition = condition
		_body = body


	func get_option() -> ESCGrammarExpr:
		return _option


	func get_condition() -> ESCGrammarExpr:
		return _condition


	func get_body() -> ESCGrammarStmt:
		return _body


	func accept(visitor):
		return await visitor.visit_dialog_option_stmt(self)


class Dialog extends ESCGrammarStmt:
	var _args: Array:
		get = get_args
	var _options: Array:
		get = get_options


	func init(args: Array, options: Array):
		_options = options
		_args = args


	func get_options() -> Array:
		return _options


	func get_args() -> Array:
		return _args


	func accept(visitor):
		return await visitor.visit_dialog_stmt(self)


class Break extends ESCGrammarStmt:
	var _levels: ESCGrammarExpr:
		get = get_levels


	func init(levels: ESCGrammarExpr):
		_levels = levels


	func get_levels() -> ESCGrammarExpr:
		return _levels


	func accept(visitor):
		return await visitor.visit_break_stmt(self)


class Done extends ESCGrammarStmt:
	func accept(visitor):
		return await visitor.visit_done_stmt(self)
