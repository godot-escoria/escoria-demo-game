# `camera_shift x y [time] [type]`
#
# Shift camera by `x` and `y` pixels over `time` seconds. `type` is any of the 
# Tween.TransitionType values without the prefix, eg. LINEAR, QUART or CIRC; 
# defaults to QUART.
#
# @ESC
extends ESCBaseCommand
class_name CameraShiftCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_INT, TYPE_INT, [TYPE_INT, TYPE_REAL], TYPE_STRING],
		[null, null, 1, "QUAD"]
	)
	

# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object("camera").node as ESCCamera)\
		.shift(
			command_params[0],
			command_params[1],
			command_params[2],
			command_params[3]
		)
	return ESCExecution.RC_OK
