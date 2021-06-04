# A statement in an ESC file
extends Object
class_name ESCStatement


# Emitted when the event did finish running
signal finished(return_code)


# The list of ESC commands
var statements: Array = []


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
