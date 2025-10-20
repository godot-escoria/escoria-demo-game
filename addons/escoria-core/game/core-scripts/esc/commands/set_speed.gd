## `set_speed(object: String, speed: Integer)`
##
## Sets the speed of a `ESCPlayer` or movable `ESCItem`.[br]
##[br]
## **Parameters**[br]
##[br]
## - *object*: Global ID of the `ESCPlayer` or movable `ESCItem`[br]
## - *speed*: Speed value for `object` in pixels per second.
##
## @ESC
extends ESCBaseCommand
class_name SetSpeedCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_INT],
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
	(escoria.object_manager.get_object(command_params[0]).node as ESCItem).\
			set_velocity(command_params[1])
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
