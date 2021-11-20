# `camera_shift x y [time] [type]`
#
# Shifts the camera by the given horizontal and vertical amounts.
#
# **Parameters**
#
# - *x*: Shift by x pixels along the x-axis
# - *y*: Shift by y pixels along the y-axis
# - *time*: Number of seconds the transition should take, with a value of `0`
#   meaning the zoom should happen instantly (default: `1`)
# - *type*: Transition type to use (default: `QUAD`)
#
# Supported transitions include the names of the values used 
# in the "TransitionType" enum of the "Tween" type (without the "TRANS_" prefix):
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
