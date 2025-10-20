## `inc_global(name: String, value: Integer)`
##
## Adds the given value to the specified global.[br]
##[br]
## **Parameters**[br]
##[br]
## - *name*: Name of the global to be changed[br]
## - *value*: Value to be added (default: 1)[br]
##
## @ESC
extends ESCBaseCommand
class_name IncGlobalCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING, TYPE_FLOAT],
		[null, 1]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## - arguments: The arguments to validate.[br]
## [br]
## *Returns* True if the arguments are valid, false otherwise.
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.globals_manager.has(arguments[0]):
		raise_error(self, "Invalid global. Global %s does not exist." % arguments[0])
		return false

	var global_value = escoria.globals_manager.get_global(arguments[0])

	if not (global_value is float or global_value is int):
		raise_error(self, "Invalid global. Global %s isn't a float value." % arguments[0])
		return false
	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	escoria.globals_manager.set_global(
		command_params[0],
		escoria.globals_manager.get_global(command_params[0]) +\
				command_params[1]
	)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
