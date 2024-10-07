# A statement in an ESC file
extends Reference
class_name ESCStatement


# Emitted when the event did finish running
signal finished(event, return_code)

# Emitted when the event was interrupted
signal interrupted(event, return_code)


# The list of ESC commands
var statements: Array = []

# The source of this statement, e.g. an ESC script or a class.
var source: String = ""

# Indicates whether this event was interrupted.
var _is_interrupted: bool = false

# Indictates whether this statement was completed
var is_completed: bool = false

# Currently running statement
var current_statement: ESCStatement = null

# Id of the statement to start from. By default, equal to 0.
var from_statement_id = 0

# If true, conditions will not be tested and are always considered true
var bypass_conditions = false


# Returns a Dictionary containing statements data for serialization
func exported() -> Dictionary:
	var export_dict: Dictionary = {}
	export_dict.class = "ESCStatement"
	export_dict.source = source
	export_dict._is_interrupted = _is_interrupted
	export_dict.is_completed = is_completed
	export_dict.from_statement_id = from_statement_id
	export_dict.current_statement = current_statement.exported() if current_statement != null else null
	export_dict.statements = []
	for s in statements:
		export_dict.statements.push_back(s.exported())
	return export_dict


# Check whether the statement should be run based on its conditions
func is_valid() -> bool:
	for condition in self.conditions:
		if not (condition as ESCCondition).run():
			return false
	return true


# Execute this statement and return its return code
func run() -> int:
	var final_rc = ESCExecution.RC_OK

	var statement_id = 0
	for statement in statements:
		from_statement_id = statement_id
		statement_id = statement_id + 1
		current_statement = statement

		if _is_interrupted:
			final_rc = ESCExecution.RC_INTERRUPTED
			statement.interrupt()
			emit_signal("interrupted", self, statement, final_rc)
			return final_rc

		if bypass_conditions or statement.is_valid():
			var rc = statement.run()
			if rc is GDScriptFunctionState:
				rc = yield(rc, "completed")
				escoria.logger.debug(
					self,
					"Statement (%s) was completed." % statement
				)
			if rc == ESCExecution.RC_REPEAT:
				return self.run()
			elif rc != ESCExecution.RC_OK:
				final_rc = rc
				break
			elif rc == ESCExecution.RC_OK:
				current_statement.is_completed = true

	emit_signal("finished", self, current_statement, final_rc)
	is_completed = true
	return final_rc


# Interrupt the statement in the middle of its execution.
func interrupt():
	escoria.logger.info(
		self,
		"Interrupting event %s (%s)."
				% [self.name if "name" in self else "group", str(self)]
	)
	_is_interrupted = true
	for statement in statements:
		if statement.has_method("interrupt"):
			statement.interrupt()


# Resets an interrupted event
func reset_interrupt():
	_is_interrupted = false
	for statement in statements:
		statement.reset_interrupt()
