## `set_global(name: String, value: String|Integer|Boolean[, force: Boolean=false])`
##
## Changes the value of a global.[br]
##[br]
## **Parameters**[br]
##[br]
## - *name*: Name of the global[br]
## - *value*: Value to set the global to (can be of type string, boolean, integer
##   or float)[br]
## - *force*: if false, setting a global whose name is reserved will
##   trigger an error. Defaults to false. Reserved globals are: ESC_LAST_SCENE,
##   FORCE_LAST_SCENE_NULL, ANIMATION_RESOURCES, ESC_CURRENT_SCENE
##
## @ESC
extends ESCBaseCommand
class_name SetGlobalCommand

## The list of illegal strings that cannot be used in global names.
const ILLEGAL_STRINGS = ["/"]


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, [TYPE_INT, TYPE_BOOL, TYPE_STRING], TYPE_BOOL],
		[null, null, false]
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

	for s in ILLEGAL_STRINGS:
		if s in arguments[0]:
			raise_error(
				self,
				"Invalid global variable. Global variable '%'s cannot contain the string '%s'."
					% [arguments[0], s]
			)
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
		command_params[1],
		command_params[2]
	)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
