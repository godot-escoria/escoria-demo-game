# `turn_to object degrees [immediate]`
# 
# Turns object to a degrees angle with a directions animation.
#
# 0 sets object facing forward, 90 sets it 90 degrees clockwise ("east") etc.
# When turning to the destination angle, animations are played if they're 
# defined in animations. object must be player or interactive. degrees must 
# be between [0, 360] or an error is reported.
#
# Set immediate to true to show directly switch to the direction and not
# show intermediate angles
#  
# @ESC
extends ESCBaseCommand
class_name TurnToCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_INT, TYPE_BOOL],
		[null, null, false]
	)
	

# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"turn_to: invalid object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	if arguments[1] < 0 or arguments[1] > 360:
		escoria.logger.report_errors(
			"turn_to: invalid degrees",
			[
				"Degree %d not between 0 and 360" % arguments[1]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]).node as ESCItem)\
		.set_angle(
			command_params[1],
			command_params[2]
		)
	return ESCExecution.RC_OK
