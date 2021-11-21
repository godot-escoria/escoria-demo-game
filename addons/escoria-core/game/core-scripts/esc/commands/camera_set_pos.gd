# `camera_set_pos speed x y`
#
# Moves the camera to the given position.
#
# **Parameters**
#
# - *speed*: Number of seconds the transition should take
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


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object("_camera").node as ESCCamera)\
			.set_target(
				Vector2(command_params[1], command_params[2]), 
				command_params[0]
			)
	return ESCExecution.RC_OK
