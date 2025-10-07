## `set_active object active`[br]
## [br]
## Changes the "active" state of the object.[br]
## Inactive objects are invisible in the room.[br]
## [br]
## #### Parameters[br]
## [br]
## - *object* Global ID of the object[br]
## - *active* Whether `object` should be active. `active` can be `true` or `false`.[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name SetActiveCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_BOOL],
		[null, null]
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

	if not escoria.object_manager.has(arguments[0]):
		raise_invalid_object_error(self, arguments[0])
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
	escoria.object_manager.get_object(command_params[0]).active = \
			command_params[1]
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
