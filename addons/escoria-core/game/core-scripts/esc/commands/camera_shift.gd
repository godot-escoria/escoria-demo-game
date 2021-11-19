# `camera_shift x y [time] [type]`
#
# Shift the camera by the given location.
#
# **Parameters**
#
# - *x*: Shift by x position
# - *y*: Shift by y position
# - *time*: Number of seconds the transition should take (1)
# - *type*: Transition type to use (QUAD)
#
# The transitions, that are supported are the names of the values used 
# in the TransitionType enum of the Tween type (without the TRANS_ prefix):
#
# https://docs.godotengine.org/en/stable/classes/class_tween.html?highlight=tween#enumerations
#
# For more details see: https://docs.escoria-framework.org/camera
#
# @ESC
extends ESCBaseCommand
class_name CameraShiftCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[
			[TYPE_INT, TYPE_REAL], 
			[TYPE_INT, TYPE_REAL], 
			[TYPE_INT, TYPE_REAL], 
			TYPE_STRING
		],
		[null, null, 1, "QUAD"]
	)
	

# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object("_camera").node as ESCCamera)\
		.shift(
			Vector2(
				command_params[0],
				command_params[1]
			),
			command_params[2],
			Tween.new().get("TRANS_%s" % command_params[3])
		)
	return ESCExecution.RC_OK
