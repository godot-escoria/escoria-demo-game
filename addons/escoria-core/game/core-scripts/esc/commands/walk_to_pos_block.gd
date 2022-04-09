# `walk_to_pos_block object x y [walk_fast]`
#
# Moves the specified `ESCPlayer` or movable `ESCItem` to the absolute
# coordinates provided while playing the `object`'s walking animation.
# This command is blocking.
# This command will use the normal walk speed by default.
#
# **Parameters**
#
# - *object*: Global ID of the object to move
# - *x*: X-coordinate of target position
# - *y*: Y-coordinate of target position
# - *walk_fast*: Whether to walk fast (`true`) or normal speed (`false`).
#   (default: false)
#
# @ESC
extends ESCBaseCommand
class_name WalkToPosBlockCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3,
		[TYPE_STRING, TYPE_INT, TYPE_INT, TYPE_BOOL],
		[null, null, null, false]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.report_errors(
			"walk_to_pos_block: invalid first object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.action_manager.do(escoria.action_manager.ACTION.BACKGROUND_CLICK, [
		command_params[0],
		Vector2(command_params[1], command_params[2]), command_params[3]
	])
	yield(
		(escoria.object_manager.get_object(command_params[0]).node as ESCItem),
		"arrived"
	)
	return ESCExecution.RC_OK
