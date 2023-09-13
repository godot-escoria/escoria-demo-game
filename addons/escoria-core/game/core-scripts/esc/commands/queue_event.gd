# `queue_event object event [channel] [block]`
#
# Queue an event to run.
#
# If you queue multiple events on a channel and none of them are blocking
# events, all events will effectively run at the same time. As the events are
# placed on the channel's queue, if one event contains a blocking command, the
# next event on that channel's queue won't be processed until the blocking
# command finishes.
#
# **Parameters**
#
# - object: Object that holds the ESC script with the event
# - event: Name of the event to queue
# - channel: Channel to run the event on (default: `_front`). Using a
#   previously unused channel name will create a new channel.
# - block: Whether to wait for the queue to finish. This is only possible, if
#   the queued event is not to be run on the same event as this command
#   (default: `false`)
#
# @ESC
extends ESCBaseCommand
class_name QueueEventCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_BOOL],
		[null, null, "_front", false]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]) and not _is_current_room(arguments[0]):
		escoria.logger.error(
			self,
			"No object or room with global id '%s' found." % arguments[0]
		)
		return false

	var node = _get_scripted_node(arguments[0])

	if not "esc_script" in node or node.esc_script == "":
		escoria.logger.error(
			self,
			"Object/room with global id '%s' has no ESC script." % arguments[0]
		)
		return false

	var esc_script = escoria.esc_compiler.load_esc_file(node.esc_script)

	if not arguments[1] in esc_script.events:
		escoria.logger.error(
			self,
			"Event with name '%s' not found." % arguments[1]
		)
		return false

	if arguments[3] and not escoria.event_manager.is_channel_free(arguments[2]):
		escoria.logger.error(
			self,
			"The queue '%s' doesn't accept a new event." % arguments[2]
		)
		return false

	return true


# Return whether global_id represents the current room the player is in.
func _is_current_room(global_id: String) -> bool:
	return escoria.globals_manager.get_global(escoria.room_manager.GLOBAL_CURRENT_SCENE) == global_id


# Run the command
func run(arguments: Array) -> int:
	var node = _get_scripted_node(arguments[0])

	var esc_script = escoria.esc_compiler.load_esc_file(node.esc_script)

	return escoria.event_manager.queue_event_from_esc(
		esc_script,
		arguments[1], # event name
		arguments[2], # channel name
		arguments[3]  # whether to block
	)


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass


# Fetches the object node or current room containing the desired ESC script.
#
# PRE: If global_id represents a room, then `escoria.main.current_scene` must be valid.
#
# **Parameters**
#
# - global_id: ID of the object or room with the desired ESC script.
#
# *Returns*
#
# The object node corresponding to global_id, or the current room if global_id is invalid or does
# not refer to an object registered with the object manager.
func _get_scripted_node(global_id: String):
	var node = null

	if escoria.object_manager.has(global_id):
		node = escoria.object_manager.get_object(
			global_id
		).node
	else:
		node = escoria.main.current_scene

	return node
