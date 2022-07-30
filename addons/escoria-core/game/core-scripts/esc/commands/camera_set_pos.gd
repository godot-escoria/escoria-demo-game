# `camera_set_pos time x y`
#
# Moves the camera to the given absolute position over a time period.
#
# **Parameters**
#
# - *time*: Number of seconds the transition should take
# - *x*: Target X coordinate
# - "y*: Target Y coordinate
#
# For more details see: https://docs.escoria-framework.org/camera
#
# @ESC
extends ESCBaseCommand
class_name CameraSetPosCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3,
		[[TYPE_REAL, TYPE_INT], TYPE_INT, TYPE_INT],
		[null, null, null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	var new_pos: Vector2 = Vector2(arguments[1], arguments[2])
	var camera: ESCCamera = escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera
	# has_point() is exclusive of right-/bottom-edge
	var camera_limit_to_test: Rect2 = Rect2(camera.limit_left, camera.limit_top, camera.limit_right - camera.limit_left + 1, camera.limit_bottom - camera.limit_top + 1)
	var camera_limit: Rect2 = Rect2(camera.limit_left, camera.limit_top, camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top)

	if not camera_limit_to_test.has_point(new_pos):
		escoria.logger.warn(
			self,
			"[%s]: invalid camera position. Camera cannot be moved to %s as this is outside the current camera limit %s."
				% [
					get_command_name(),
					new_pos,
					camera_limit
				]
		)
		return false

	return true


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
			.set_target(
				Vector2(command_params[1], command_params[2]),
				command_params[0]
			)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.warn(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
