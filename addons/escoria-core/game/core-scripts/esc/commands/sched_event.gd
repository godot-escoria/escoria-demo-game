# `sched_event time object event`
# 
# Schedules the execution of an "event" found in "object" in a time in seconds. 
# If another event is running at the time, execution starts when the running 
# event ends.
#
# @ESC
extends ESCBaseCommand
class_name SchedEventCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		3, 
		[TYPE_INT, TYPE_STRING, TYPE_STRING],
		[null, null, null]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.has(arguments[1]):
		escoria.logger.report_errors(
			"sched_event: invalid object",
			[
				"Object with global id %s not found" % arguments[1]
			]
		)
		return false
	elif not escoria.object_manager.get_object(arguments[1]).events\
			.has(arguments[2]):
		escoria.logger.report_errors(
			"sched_event: invalid object event",
			[
				"Object with global id %s has no event %s" % [
					arguments[1],
					arguments[2],
				]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.event_manager.schedule_event(
		escoria.object_manager.get_object(command_params[1])\
			.events[command_params[2]],
		command_params[0]
	)
	return ESCExecution.RC_OK
