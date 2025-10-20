## `camera_set_target(time: Number, object: String)`
##
## Configures the camera to follow the specified target `object` as it moves
## around the current room. The transition to focus on the `object` will happen
## over a time period.[br]
##[br]
## **Parameters**[br]
##[br]
## - *time*: Number of seconds the transition should take to move the camera
##   to follow `object`[br]
## - *object*: Global ID of the target object[br]
##[br]
## For more details see: https://docs.escoria-framework.org/camera
##
## @ESC
extends ESCCameraBaseCommand
class_name CameraSetTargetCommand


###Returns the descriptor of the arguments of this command.[br]
###[br]
###*Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[[TYPE_FLOAT, TYPE_INT], TYPE_STRING],
		[null, null]
	)


###Validates whether the given arguments match the command descriptor.[br]
###[br]
########Parameters[br]
###[br]
###- arguments: The arguments to validate.[br]
###[br]
###*Returns* True if the arguments are valid, false otherwise.
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[1]):
		raise_invalid_object_error(self, arguments[1])
		return false

	return true


###Runs the command.[br]
###[br]
########Parameters[br]
###[br]
###- command_params: The parameters for the command.[br]
###[br]
###*Returns* The execution result code.
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
		.set_target(
			escoria.object_manager.get_object(command_params[1]).node,
			command_params[0]
		)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
