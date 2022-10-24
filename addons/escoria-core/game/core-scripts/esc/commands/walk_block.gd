# `walk_block object target [walk_fast]`
#
# Moves the specified `ESCPlayer` or movable `ESCItem` to the `target` 
# ESCItem's location while playing `object`'s walking animation. This command
# is blocking.
# This command will use the normal walk speed by default.
# If the `target` ESCItem has a child ESCLocation node, the walk destination
# will be the position of the ESCLocation.
#
# **Parameters**
#
# - *object*: Global ID of the object to move
# - *target*: Global ID of the target object
# - *walk_fast*: Whether to walk fast (`true`) or normal speed (`false`).
#   (default: false)
#
# @ESC
extends ESCBaseCommand
class_name WalkBlockCommand


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
		escoria.logger.error(
			self,
			"[%s]: invalid first object. The object to make walk with global id %s was not found."
					% [get_command_name(), arguments[0]]
		)
		return false
	if not escoria.object_manager.has(arguments[1]):
		escoria.logger.error(
			self,
			"[%s]: invalid second object. The object to walk to with global id %s was not found."
					% [get_command_name(), arguments[1]]
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
	yield(walking_object_node, "arrived")
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	if walking_object_node != null and is_instance_valid(walking_object_node) \
			and not walking_object_node is ESCPlayer:
		walking_object_node.stop_walking_now()
