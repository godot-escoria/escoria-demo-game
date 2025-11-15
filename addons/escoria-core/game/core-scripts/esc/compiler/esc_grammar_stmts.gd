## Implements all statements in the scripting language's grammar. These classes
## represent language constructs as part of a script's syntax tree.
class_name ESCGrammarStmts


## Represents a local (non-global) variable declaration and a possible initializer.
class Var extends ESCGrammarStmt:
	var _name: ESCToken:
		get = get_name
	var _initializer: ESCGrammarExpr:
		get = get_initializer


	## Initialization method. Must be called after instantiation.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |name|`ESCToken`|Token representing the variable's name.|yes|[br]
	## |initializer|`ESCGrammarExpr`|Expression used to compute the initial value.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func init(name: ESCToken, initializer: ESCGrammarExpr):
		_name = name
		_initializer = initializer


	## The variable's name (as an `ESCToken`).[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the variable's name (as an `ESCToken`). (`ESCToken`)
	func get_name() -> ESCToken:
		return _name


	## The initalizer expression.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the initalizer expression. (`ESCGrammarExpr`)
	func get_initializer() -> ESCGrammarExpr:
		return _initializer


	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_var_stmt(self)


## Represents a global variable declaration and a possible initializer.
class Global extends ESCGrammarStmt:
	var _name: ESCToken:
		get = get_name
	var _initializer: ESCGrammarExpr:
		get = get_initializer


	## Initialization method. Must be called after instantiation.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |name|`ESCToken`|Token representing the variable's name.|yes|[br]
	## |initializer|`ESCGrammarExpr`|Expression used to compute the initial value.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func init(name: ESCToken, initializer: ESCGrammarExpr):
		_name = name
		_initializer = initializer


	## The global variable's name (as an `ESCToken`).[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the global variable's name (as an `ESCToken`). (`ESCToken`)
	func get_name() -> ESCToken:
		return _name


	## The initalizer expression.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the initalizer expression. (`ESCGrammarExpr`)
	func get_initializer() -> ESCGrammarExpr:
		return _initializer


	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_global_stmt(self)


## Represents an Escoria event, e.g. `:look`. An event can also be given a "target"
## to act on, e.g. `:use "wrench"`.
class Event extends ESCGrammarStmt:
	## Signal fired when the event has finished.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	signal finished

	## Signal fired if the event has been interrupted.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
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
	var _object_global_id: String: # This may be empty, e.g. if the event is attached to a room.
		get = get_object_global_id

	var _running_command:
		set = set_running_command,
		get = get_running_command

	# Indicates whether this event was interrupted.
	var _is_interrupted: bool = false:
		get = is_interrupted

	var source: String = "" # TODO: Make proper use of this


	## Valid event flags[br]
	##[br]
	## * TK: stands for "telekinetic". It means the player won't walk over to
	##   the item to say the line.[br]
	## * NO_TT: stands for "No tooltip". It hides the tooltip for the duration of
	##   the event. Probably not very useful, because events having multiple
	##   say commands in them are automatically hidden.[br]
	## * NO_UI: stands for "No User Inteface". It hides the UI for the duration of
	##   the event. Useful when you want something to look like a cut scene but not
	##   disable input for skipping dialog.[br]
	## * NO_SAVE: disables saving. Use this in cut scenes and anywhere a
	##   badly-timed autosave would leave your game in a messed-up state.
	enum {
		FLAG_TK = 1,
		FLAG_NO_TT = 2,
		FLAG_NO_UI = 4,
		FLAG_NO_SAVE = 8
	}


	## Initialization method. Must be called after instantiation.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |name|`ESCToken`|Token representing the event name.|yes|[br]
	## |target|`ESCGrammarExprs.Literal`|a literal representing the global ID of an object the event is meant to act on; can be null.|yes|[br]
	## |flags|`Dictionary`|an array containing event flags to be applied; can be null/empty.|yes|[br]
	## |body|`ESCGrammarStmts.Block`|the body of the event; this is the script block that will be executed when the event is run.|yes|[br]
	## |object_global_id|`String`|the object/room the event is attached to, if any (may be empty)|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func init(name: ESCToken, target: ESCGrammarExprs.Literal, flags: Dictionary, body: ESCGrammarStmts.Block, object_global_id: String):
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
		_object_global_id = object_global_id


	## The event's name (as an `ESCToken`).[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the event's name (as an `ESCToken`). (`ESCToken`)
	func get_name() -> ESCToken:
		return _name


	## The target as a literal.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the target as a literal. (`ESCGrammarExprs.Literal`)
	func get_target() -> ESCGrammarExprs.Literal:
		return _target


	## A string containing the name of the target, if it exists.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns a string containing the name of the target, if it exists. (`String`)
	func get_target_name() -> String:
		return _target.get_value() if _target != null else ""


	## The name of the event as a string.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the name of the event as a string. (`String`)
	func get_event_name() -> String:
		return _name.get_lexeme()


	## The flags set for this event. Note that this is an integer that serves as a collection of mutually exclusive bits.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the flags set for this event. Note that this is an integer that serves as a collection of mutually exclusive bits. (`int`)
	func get_flags() -> int:
		return _flags


	func get_flags_with_conditions() -> Dictionary:
		return _flags_with_conditions


	func add_flag(flag: ESCEvent.FLAGS):
		_flags |= flag


	## The body of the event. This is the script block that will be executed when the event is run.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the body of the event. This is the script block that will be executed when the event is run. (`ESCGrammarStmts.Block`)
	func get_body() -> ESCGrammarStmts.Block:
		return _body


	func get_object_global_id() -> String:
		return _object_global_id


	## The number of top-level statements in the body. Generally only useful for internal purposes.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the number of top-level statements in the body. Generally only useful for internal purposes. (`int`)
	func get_num_statements_in_block() -> int:
		return _body.get_statements().size()


	## The command currently being executed in this event.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the command currently being executed in this event. (`Variant`)
	func get_running_command():
		return _running_command


	## Sets the command that is currently being executed in this event.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |cmd|`Variant`|Command currently being executed for this event.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func set_running_command(cmd) -> void:
		_running_command = cmd


	## Clears the currently-running command.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func clear_running_command() -> void:
		_running_command = null


	## Forces the event to be interrupted.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func interrupt() -> void:
		_is_interrupted = true

		if _running_command:
			_running_command.interrupt()


	## True iff the event has been interrupted.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns true iff the event has been interrupted. (`bool`)
	func is_interrupted() -> bool:
		return _is_interrupted


	## Resets the "is interrupted" flag.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func reset_interrupt() -> void:
		_is_interrupted = false


	## Emits the `finished` signal along with the indicated return code (`rc`).[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |rc|`int`|Return code emitted when the statement signals completion.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func emit_finished(rc: int):
		emit_signal("finished", self, null, rc)


	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_event_stmt(self)


## Represents a block of statements in a script.
class Block extends ESCGrammarStmt:
	var _statements: Array:
		get = get_statements


	## Initialization method. Must be called after instantiation.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |statements|`Array`|Statements contained within the block body.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func init(statements: Array):
		_statements = statements


	## The statements contained in this block as an array.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the statements contained in this block as an array. (`Array`)
	func get_statements() -> Array:
		return _statements


	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_block_stmt(self)


## Represents an expression to be evaluated that is contained within a statement.
class ESCExpression extends ESCGrammarStmt:
	var _expression: ESCGrammarExpr:
		get = get_expression


	## Initialization method. Must be called after instantiation.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |expression|`ESCGrammarExpr`|Expression evaluated by the statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func init(expression: ESCGrammarExpr):
		_expression = expression


	## The expression this `ESCExpression` represents.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the expression this `ESCExpression` represents. (`ESCGrammarExpr`)
	func get_expression() -> ESCGrammarExpr:
		return _expression


	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_expression_stmt(self)


## Represents an `if` statement. Uses the form:[br]
##```[br]
##if <expression>:[br]
## 	<block>[br]
##elif <expression>:[br]
## 	<block>[br]
##else:[br]
## 	<block>[br]
##```[br]
##[br]
## - Can contain multiple `elif` blocks.[br]
## - `elif` and `else` blocks are optional.
class If extends ESCGrammarStmt:
	var _condition: ESCGrammarExpr:
		get = get_condition
	var _then_branch: ESCGrammarStmts.Block:
		get = get_then_branch
	var _elif_branches: Array:
		get = get_elif_branches
	var _else_branch: ESCGrammarStmts.Block:
		get = get_else_branch


	## Initialization method. Must be called after instantiation.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |condition|`ESCGrammarExpr`|the expression to be evaluated and tested for the `if` block.|yes|[br]
	## |then_branch|`ESCGrammarStmts.Block`|the block of statements to be executed should `condition` evaluate to `true`.|yes|[br]
	## |elif_branches|`Array`|an array containing any desired `elif` branches, with each element corresponding to its own `if` statement.|yes|[br]
	## |else_branch|`ESCGrammarStmts.Block`|the block of staetments to be executed should `condition` evaluate to `false`.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func init(condition: ESCGrammarExpr, then_branch: ESCGrammarStmts.Block, elif_branches: Array, else_branch: ESCGrammarStmts.Block):
		_condition = condition
		_then_branch = then_branch
		_elif_branches = elif_branches
		_else_branch = else_branch


	## The expression/predicate to be evaluated for the `if` block.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the expression/predicate to be evaluated for the `if` block. (`ESCGrammarExpr`)
	func get_condition() -> ESCGrammarExpr:
		return _condition


	## The block of statements to be executed should `condition` evaluate to `true`.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the block of statements to be executed should `condition` evaluate to `true`. (`ESCGrammarStmts.Block`)
	func get_then_branch() -> ESCGrammarStmts.Block:
		return _then_branch


	## The array of `elif` branches to include as part of this `if` statement.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the array of `elif` branches to include as part of this `if` statement. (`Array`)
	func get_elif_branches() -> Array:
		return _elif_branches


	## The block of statements to be executed should `condition` evaluate to `false`.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the block of statements to be executed should `condition` evaluate to `false`. (`ESCGrammarStmts.Block`)
	func get_else_branch() -> ESCGrammarStmts.Block:
		return _else_branch


	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_if_stmt(self)


## Represents a `while` loop. Uses the form:[br]
##```[br]
##while <condition>:[br]
##	<block>[br]
##```
class While extends ESCGrammarStmt:
	var _condition: ESCGrammarExpr:
		get = get_condition
	var _body: ESCGrammarStmt:
		get = get_body


	## Initialization method. Must be called after instantiation.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |condition|`ESCGrammarExpr`|the expression to be evaluated and tested in order for the `while` loop to be entered/continue executing.|yes|[br]
	## |body|`ESCGrammarStmt`|the block of statements to be executed should `condition` evaluate to `true`.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func init(condition: ESCGrammarExpr, body: ESCGrammarStmt):
		_condition = condition
		_body = body


	## The expression/predicate to be evaluated for the `while` block.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the expression/predicate to be evaluated for the `while` block. (`ESCGrammarExpr`)
	func get_condition() -> ESCGrammarExpr:
		return _condition


	## The block of statements to be executed should `condition` evaluate to `true`.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the block of statements to be executed should `condition` evaluate to `true`. (`ESCGrammarStmt`)
	func get_body() -> ESCGrammarStmt:
		return _body


	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_while_stmt(self)


## Represents the equivalent of the GDScript `pass` statement and behaves exactly the same way.
class Pass extends ESCGrammarStmt:
	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_pass_stmt(self)


## Represents a `stop` statement. Will stop the rest of the event from executing.
class Stop extends ESCGrammarStmt:
	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_stop_stmt(self)


## Represents an option contained within a dialog. Usually of the form:[br]
##[br]
##```[br]
##- <expression> [condition][br]
## 	<block>[br]
##```[br]
##[br]
## ...where:[br]
## - The result of `<expression>` is displayed in a dialog choice UI. The player
## will be able to select the displayed text as a dialog option.[br]
## - `[condition]` is optional and, if specified, is used to determine
## whether the dialog option is displayed.[br]
## - `<block>` is a block of statements to be executed and must be indented like
## a typical block.[br]
##[br]
## E.g.[br]
##```[br]
##- "Why are you here?" [!option_already_visited][br]
##	say("current_player", "Why are you here?")[br]
##	say("worker", "Because I work here.")[br]
##```
class DialogOption extends ESCGrammarStmt:
	var _option: ESCGrammarExpr:
		get = get_option
	var _condition: ESCGrammarExpr:
		get = get_condition
	var _body: ESCGrammarStmt:
		get = get_body


	## Initialization method. Must be called after instantiation.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |option|`ESCGrammarExpr`|the expression whose results will be displayed on screen as an option to be selected alongside any other options at the current level|yes|[br]
	## |condition|`ESCGrammarExpr`|an optional condition to be evaluated that is used to determine whether the option should be displayed at all|yes|[br]
	## |body|`ESCGrammarStmt`|the block of statements to be executed should this dialog option be selected|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func init(option: ESCGrammarExpr, condition: ESCGrammarExpr, body: ESCGrammarStmt):
		_option = option
		_condition = condition
		_body = body


	## The option expression.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the option expression. (`ESCGrammarExpr`)
	func get_option() -> ESCGrammarExpr:
		return _option


	## The condition for this option, if one exists.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the condition for this option, if one exists. (`ESCGrammarExpr`)
	func get_condition() -> ESCGrammarExpr:
		return _condition


	## The statements of the option to be executed should the option be selected.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the statements of the option to be executed should the option be selected. (`ESCGrammarStmt`)
	func get_body() -> ESCGrammarStmt:
		return _body


	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_dialog_option_stmt(self)


## Represents a dialog between characters. Can be nested. Begin each block of dialog
## with `?!`. Can take up to three optional arguments (detailed in the `init` method).[br]
##[br]
## (A block of dialog follows the same rules as a block of script statements, including
## the need to use appropriate indentation.)[br]
##[br]
## E.g.[br]
##```[br]
##?![br]
##	- "This is the first dialog option!"[br]
##		say("current_player", "This is the first dialog option!")[br]
##		say("worker", "That's nice. Can you show me some other dialog options?")[br]
##		?![br]
##			- "This is a nested dialog option, and appears on its own!"[br]
##				say("current_player", "This is a nested dialog option, and appears on its own!"[br]
##```[br]
##[br]
class Dialog extends ESCGrammarStmt:
	var _args: Array:
		get = get_args
	var _options: Array:
		get = get_options


	## Initialization method. Must be called after instantiation.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |args|`Array`|the arguments pertaining to this dialog; the array is typically ordered: Path to avatar to be used for this dialog, Timeout (in seconds) until the default option is automatically selected, Timeout option to be selected once the timeout is reached.|yes|[br]
	## |options|`Array`|the dialog options available to this dialog|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func init(args: Array, options: Array):
		_options = options
		_args = args


	## The options available to this dialog.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the options available to this dialog. (`Array`)
	func get_options() -> Array:
		return _options


	## The arguments for this dialog as described in the `init` method.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the arguments for this dialog as described in the `init` method. (`Array`)
	func get_args() -> Array:
		return _args


	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_dialog_stmt(self)


## Represents a `break` statement. Can be used to break out of a loop or a dialog.
## If used to break out of a nested dialog, an optional argument can be given that
## specifies how many levels of nested dialogs to break out of, including out of
## all nested dialogs.
class Break extends ESCGrammarStmt:
	var _levels: ESCGrammarExpr:
		get = get_levels


	## Initialization method. Must be called after instantiation.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |levels|`ESCGrammarExpr`|an expression whose result will be used to determine how many levels of nested dialogs to break out from; not applicable for loops.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func init(levels: ESCGrammarExpr):
		_levels = levels


	## The expression whose result represents the number of nested dialog levels to break out from.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## None.
	## [br]
	## #### Returns[br]
	## [br]
	## Returns the expression whose result represents the number of nested dialog levels to break out from. (`ESCGrammarExpr`)
	func get_levels() -> ESCGrammarExpr:
		return _levels


	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_break_stmt(self)


## Represents a `done` staetment. Used to end and break out of the top-level of
## the current dialog, regardless of the current nested depth.
class Done extends ESCGrammarStmt:
	## Method to invoke visitor-specific code.[br]
	## [br]
	## #### Parameters[br]
	## [br]
	## | Name | Type | Description | Required? |[br]
	## |:-----|:-----|:------------|:----------|[br]
	## |visitor|`Variant`|Visitor instance invoked to process this statement.|yes|[br]
	## [br]
	## #### Returns[br]
	## [br]
	## Returns nothing.
	func accept(visitor):
		return await visitor.visit_done_stmt(self)
