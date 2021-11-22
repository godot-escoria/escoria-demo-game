# `queue_event object event [channel] [block]`
#
# Queue another event to run
#
# **Parameters**
#
# - object: Object that holds the ESC script with the event
# - event: Name of the event to queue
# - channel: Channel to run the event on (default: `_front`)
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
	

# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"queue_event.gd:validate",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	var node = escoria.object_manager.objects.get(
		arguments[0]
	).node
	if not "esc_script" in node or node.esc_script == "":
		escoria.logger.report_errors(
			"queue_event.gd:validate",
			[
				"Object with global id %s has no ESC script" % arguments[0]
			]
		)
		return false
	var esc_script = escoria.esc_compiler.load_esc_file(node.esc_script)
	if not arguments[1] in esc_script.events:
		escoria.logger.report_errors(
			"queue_event.gd:validate",
			[
				"Event with name %s not found" % arguments[1]
			]
		)
		return false
	if arguments[3] and not escoria.event_manager.is_channel_free(arguments[2]):
		escoria.logger.report_errors(
			"queue_event.gd:validate",
			[
				"The queue %s doesn't accept a new event." % arguments[2]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(arguments: Array) -> int:
	var node = escoria.object_manager.objects.get(
		arguments[0]
	).node
	var esc_script = escoria.esc_compiler.load_esc_file(node.esc_script)
	if arguments[2] == "_front":
		escoria.event_manager.queue_event(esc_script.events[arguments[1]])
	else:
		escoria.event_manager.queue_background_event(
			arguments[2],
			esc_script.events[arguments[1]]
		)
	if arguments[3]:
		if arguments[2] == "_front":
			var rc = yield(escoria.event_manager, "event_finished")
			while rc[1] != arguments[1]:
				rc = yield(escoria.event_manager, "event_finished")
			return rc
		else:
			var rc = yield(
				escoria.event_manager, 
				"background_event_finished"
			)
			while rc[1] != arguments[1] and rc[2] != arguments[2]:
				rc = yield(
					escoria.event_manager,
					"background_event_finished"
				)
			return rc
	return ESCExecution.RC_OK
