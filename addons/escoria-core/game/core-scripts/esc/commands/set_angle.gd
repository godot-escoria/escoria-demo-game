# `set_angle object degrees`
#
# Turns object to a degrees angle without animations. 0 sets object facing 
# forward, 90 sets it 90 degrees clockwise ("east") etc. When turning to the 
# destination angle, animations are played if they're defined in animations.
#
# object must be player or interactive. degrees must be between [0, 360] or an 
# error is reported.
#
# @ESC
extends ESCBaseCommand
class_name SetAngleCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_INT],
		[null, null]
	)
	

# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"set_angle: invalid object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	# HACK Countering the fact that angle_to_point() function gives
	# angle against X axis not Y, we need to check direction using (angle-90°).
	# Since the ESC command already gives the right angle, we add 90.
	escoria.object_manager.get_object(command_params[0]).node\
			.set_angle(wrapi(int(command_params[1]) + 90, 0, 360))
	return ESCExecution.RC_OK
	
