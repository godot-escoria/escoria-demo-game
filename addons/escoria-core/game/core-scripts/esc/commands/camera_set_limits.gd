## `camera_set_limits(camlimits_id: Integer)`
##
## Limits the current camera's movement to a limit defined in the `ESCRoom`'s
## definition. A limit is defined as an upper-left (x, y) coordinate, a width
## and a height that the camera must stay within. Multiple limits can be
## defined for a room, allowing for new areas to be seen once they have
## been 'unlocked'.[br]
##[br]
## **Parameters**[br]
##[br]
## - *camlimits_id*: Index of the camera limit defined in the `camera limits`
##   list of the current `ESCRoom`[br]
##[br]
## For more details see: https://docs.escoria-framework.org/camera
##
## @ESC
extends ESCCameraBaseCommand
class_name CameraSetLimitsCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_INT],
		[null]
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

	if escoria.main.current_scene.camera_limits.size() < arguments[0]:
		raise_error(self, "Invalid limits id. Camera limit id (%d) is larger than the number of limits defined in this scene (%d)."
				% [
					arguments[0],
					escoria.main.current_scene.camera_limits.size()
				]
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
	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera
	camera.clamp_to_viewport_limits()
	escoria.main.set_camera_limits(command_params[0])

	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
