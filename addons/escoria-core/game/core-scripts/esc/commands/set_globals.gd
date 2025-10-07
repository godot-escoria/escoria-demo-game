## `set_globals pattern value`[br]
## [br]
## Changes the value of multiple globals using a wildcard pattern, where `*`
## matches zero or more arbitrary characters and `?` matches any single
## character except a period (".").[br]
## [br]
## #### Parameters[br]
## [br]
## - *pattern*: Pattern to use to match the names of the globals to change[br]
## - *value*: Value to set (can be of type string, boolean, integer or float)[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name SetGlobalsCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, [TYPE_BOOL, TYPE_STRING, TYPE_INT]],
		[null, null]
	)


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	escoria.globals_manager.set_global_wildcard(
		command_params[0],
		command_params[1]
	)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
