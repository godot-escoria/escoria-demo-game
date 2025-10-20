## `camera_set_pos(time: Number, x: Integer, y: Integer)`
##
## Moves the camera to the given absolute position over a time period.[br]
##[br]
## **Parameters**[br]
##[br]
## - *time*: Number of seconds the transition should take[br]
## - *x*: Target X coordinate[br]
## - "y*: Target Y coordinate[br]
##[br]
## For more details see: https://docs.escoria-framework.org/camera
##
## @ESC
extends ESCCameraBaseCommand
class_name CameraSetPosCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3,
		[[TYPE_FLOAT, TYPE_INT], TYPE_INT, TYPE_INT],
		[null, null, null]
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

	var new_pos: Vector2 = Vector2(arguments[1], arguments[2])
	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera

	if not camera.check_point_is_inside_viewport_limits(new_pos):
		generate_viewport_warning(new_pos, camera)
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
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
			.set_target(
				Vector2(command_params[1], command_params[2]),
				command_params[0]
			)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
