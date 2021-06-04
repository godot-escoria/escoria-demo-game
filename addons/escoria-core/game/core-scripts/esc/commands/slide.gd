# `slide object1 object2 [speed]`
#
# Moves object1 towards the position of object2, at the speed determined by 
# object1's "speed" property, unless overridden. This command is non-blocking. 
# It does not respect the room's navigation polygons, so you can move items 
# where the player can't walk.
#
# @STUB
# @ESC
extends ESCBaseCommand
class_name SlideCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING, TYPE_INT],
		[null, null, null]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"slide: invalid first object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false	
	if not escoria.object_manager.objects.has(arguments[1]):
		escoria.logger.report_errors(
			"slide: invalid second object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.logger.report_errors(
		"slide: command not implemented",
		[]
	)
	return ESCExecution.RC_ERROR
