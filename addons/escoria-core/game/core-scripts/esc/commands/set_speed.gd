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


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_INT],
		[null, null]
	)

## Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		raise_invalid_object_error(self, arguments[0])
		return false
	return true

## Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]).node as ESCItem).\
			set_velocity(command_params[1])
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
