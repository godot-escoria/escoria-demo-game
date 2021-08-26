# A statement in an ESC file
extends Object
class_name ESCStatement


# Emitted when the event did finish running
signal finished(return_code)

# Emitted when the event was interrupted
signal interrupted(return_code)

# The list of ESC commands
var statements: Array = []

# Indicated whether this event was interrupted.
var _is_interrupted: bool = false


# Check wether the statement should be run based on its conditions
func is_valid() -> bool:
	for condition in self.conditions:
		if not (condition as ESCCondition).run():
			return false
	return true
	
	
# Execute this statement and return its return code
func run() -> int:
	var final_rc = ESCExecution.RC_OK
	for statement in statements:
		if _is_interrupted:
			final_rc = ESCExecution.RC_CANCEL
			emit_signal("interrupted", final_rc)
			return final_rc
		
		if statement.is_valid():
			var rc = statement.run()
			if rc is GDScriptFunctionState:
				rc = yield(rc, "completed")
			if rc == ESCExecution.RC_REPEAT:
				return self.run()
			elif rc != ESCExecution.RC_OK:
				final_rc = rc
				break
	
	emit_signal("finished", final_rc)
	return final_rc


# Interrupt the statement in the middle of its execution.
func interrupt():
	escoria.logger.info("Interrupting event %s" % str(self))
	_is_interrupted = true
	for statement in statements:
		statement.interrupt()
