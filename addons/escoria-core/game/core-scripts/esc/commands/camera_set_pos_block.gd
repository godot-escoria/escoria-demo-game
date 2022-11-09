# `camera_set_pos_block time x y`
#
# Moves the camera to the given absolute position over a time period. Blocks
# until the command completes.
#
# Make sure the coordinates are reachable if camera limits have been configured.
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
extends ESCCameraBaseCommand
class_name CameraSetPosBlockCommand


# Tween for blocking
var _camera_tween: Tween


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

	if not camera.check_point_is_inside_viewport_limits(new_pos):
		generate_viewport_warning(new_pos, camera)
		return false

	_camera_tween = camera.get_tween()

	return true


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(escoria.object_manager.CAMERA).node as ESCCamera)\
			.set_target(
				Vector2(command_params[1], command_params[2]),
				command_params[0]
			)

	if command_params[0] > 0.0:
		yield(_camera_tween, "tween_completed")
	escoria.logger.debug(
			self,
			"camera_set_pos_block tween complete."
		)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
