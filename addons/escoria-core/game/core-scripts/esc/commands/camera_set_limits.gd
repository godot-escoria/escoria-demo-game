# `camera_set_limits camlimits_id`
#
# Limits the current camera's movement to a limit defined in the `ESCRoom`'s
# definition. A limit is defined as an upper-left (x, y) coordinate, a width
# and a height that the camera must stay within. Multiple limits can be
# defined for a room, allowing for new areas to be seen once they have
# been 'unlocked'.
#
# **Parameters**
#
# - *camlimits_id*: Index of the camera limit defined in the `camera limits`
#   list of the current `ESCRoom`
#
# For more details see: https://docs.escoria-framework.org/camera
#
# @ESC
extends ESCCameraBaseCommand
class_name CameraSetLimitsCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_INT],
		[null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if escoria.main.current_scene.camera_limits.size() < arguments[0]:
		escoria.logger.error(
			self,
			"[%s]: invalid limits id. Camera3D limit id (%d) is larger than the number of limits defined in this scene (%d)."
				% [
					get_command_name(),
					arguments[0],
					escoria.main.current_scene.camera_limits.size()
				]
		)
		return false

	return true


# Run the command
func run(command_params: Array) -> int:
	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera
	camera.clamp_to_viewport_limits()
	escoria.main.set_camera_limits(command_params[0])

	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
