# `walk object target [walk_fast]`
#
# Moves the specified `ESCPlayer` or movable `ESCItem` to `target`
# while playing `object`'s walking animation. This command is non-blocking.
# This command will use the normal walk speed by default.
#
# **Parameters**
#
# - *object*: Global ID of the object to move
# - *target*: Global ID of the target object
# - *walk_fast*: Whether to walk fast (`true`) or normal speed (`false`)
#   (default: false)
#
# @ESC
extends ESCBaseCommand
class_name WalkCommand


# Walking object
var walking_object_node: ESCItem

# Target object
var target_object_node: ESCObject


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_BOOL],
		[null, null, false]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.report_errors(
			"walk: invalid first object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	if not escoria.object_manager.has(arguments[1]):
		escoria.logger.report_errors(
			"walk: invalid second object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false

	walking_object_node = (escoria.object_manager.get_object(
		arguments[0]).node as ESCItem
	)
	target_object_node = escoria.object_manager.get_object(arguments[1])
	return true


# Run the command
func run(command_params: Array) -> int:
	escoria.action_manager.do(
		escoria.action_manager.ACTION.BACKGROUND_CLICK,
		command_params
	)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	if walking_object_node != null:
		walking_object_node.stop_walking_now()
