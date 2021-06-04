# `turn_to object degrees`
# 
# Turns object to a degrees angle with a directions animation.
#
# 0 sets object facing forward, 90 sets it 90 degrees clockwise ("east") etc.
# When turning to the destination angle, animations are played if they're 
# defined in animations. object must be player or interactive. degrees must 
# be between [0, 360] or an error is reported.
#  
# @STUB
# @ESC
extends ESCBaseCommand
class_name TurnToCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_INT],
		[null, true]
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
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.logger.report_errors(
		"turn_to: command not implemented",
		[]
	)
	return ESCExecution.RC_ERROR
