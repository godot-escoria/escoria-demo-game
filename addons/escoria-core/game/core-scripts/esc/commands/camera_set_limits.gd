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
extends ESCBaseCommand
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
	if not .validate(arguments):
		return false

	if escoria.main.current_scene.camera_limits.size() < arguments[0]:
		escoria.logger.report_errors(
			"camera_set_limits: invalid limits id",
			[
				"Limit id %d is bigger than limits array size %d" % [
					arguments[0],
					escoria.main.current_scene.camera_limits.size()
				]
			]
		)
		return false

	return true


# Run the command
func run(command_params: Array) -> int:
	escoria.main.set_camera_limits(command_params[0])
	return ESCExecution.RC_OK
