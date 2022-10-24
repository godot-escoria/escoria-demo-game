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

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.error(
			self,
			"Object with global id %s not found." % arguments[0]
		)
		return false
	var node = escoria.object_manager.get_object(
		arguments[0]
	).node
	if not "esc_script" in node or node.esc_script == "":
		escoria.logger.error(
			self,
			"Object with global id %s has no ESC script." % arguments[0]
		)
		return false
	var esc_script = escoria.esc_compiler.load_esc_file(node.esc_script)
	if not arguments[1] in esc_script.events:
		escoria.logger.error(
			self,
			"Event with name %s not found." % arguments[1]
		)
		return false
	if arguments[3] and not escoria.event_manager.is_channel_free(arguments[2]):
		escoria.logger.error(
			self,
			"The queue %s doesn't accept a new event." % arguments[2]
		)
		return false
	return true


# Run the command
func run(arguments: Array) -> int:
	var node = escoria.object_manager.get_object(
		arguments[0]
	).node
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
