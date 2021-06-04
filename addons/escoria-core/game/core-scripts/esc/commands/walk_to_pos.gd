# `walk_to_pos player x y`
#
# Makes the `player` walk to the position `x`/`y`.
#
# @ESC
extends ESCBaseCommand
class_name WalkToPosCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3, 
		[TYPE_STRING, TYPE_INT, TYPE_INT],
		[null, null, null]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"walk_to_pos: invalid first object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false	
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.do("walk", [
		command_params[0],
		Vector2(command_params[1], command_params[2])
	])
	return ESCExecution.RC_OK
