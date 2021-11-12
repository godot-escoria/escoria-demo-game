# `camera_push target [time] [type]`
#
# Push camera to `target`. Target must have camera_pos set. If it's of type 
# Camera2D, its zoom will be used as well as position. `type` is any of the 
# Tween.TransitionType values without the prefix, eg. LINEAR, QUART or CIRC; 
# defaults to QUART. A `time` value of 0 will set the camera immediately.
#
# @ESC
extends ESCBaseCommand
class_name CameraPushCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_STRING, [TYPE_REAL, TYPE_INT], TYPE_STRING],
		[null, 1, "QUAD"]
	)
	

# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"camera_push: invalid object",
			[
				"Object global id %s not found" % arguments[0]
			]
		)
		return false
	
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object("_camera").node as ESCCamera)\
		.push(
			escoria.object_manager.get_object(command_params[0]).node,
			command_params[1],
			Tween.new().get("TRANS_%s" % command_params[2])
		)
	return ESCExecution.RC_OK
