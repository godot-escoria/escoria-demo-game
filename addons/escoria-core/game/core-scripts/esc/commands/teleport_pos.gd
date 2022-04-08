# `teleport_pos object x y`
#
# Instantly moves an object to the specified (absolute) coordinates.
#
# **Parameters**
#
# - *object*: Global ID of the object to move
# - *x*: X-coordinate of destination position
# - *y*: Y-coordinate of destination position
#
# @ESC
extends ESCBaseCommand
class_name TeleportPosCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_INT, TYPE_INT],
		[null, null, null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.report_errors(
			"teleport_pos: invalid first object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.object_manager.get_object(command_params[0]).node.teleport_to(
		Vector2(int(command_params[1]), int(command_params[2]))
	)
	return ESCExecution.RC_OK
