# `sched_event time object event`
#
# Schedules an event to run at a later time.
#
# If another event is already running when the scheduled
# event is supposed to start, execution of the scheduled event
# begins when the already-running event ends.
#
# **Parameters**
#
# - *time*: Time in seconds until the scheduled event starts
# - *object*: Global ID of the ESCItem that holds the ESC script
# - *event*: Name of the event to schedule
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


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[1]):
		escoria.logger.error(
			self,
			"[%s]: invalid object. Object with global id %s not found."
					% [get_command_name(), arguments[1]]
		)
		return false
	elif not escoria.object_manager.get_object(arguments[1]).events\
			.has(arguments[2]):
		escoria.logger.error(
			self,
			"[%s]: invalid object event. Object with global id %s has no event %s." 
				% [
					get_command_name(),
					arguments[1],
					arguments[2],
				]
		)
		return false
	return true


# Run the command
func run(command_params: Array) -> int:
	escoria.event_manager.schedule_event(
		escoria.object_manager.get_object(command_params[1])\
			.events[command_params[2]],
		command_params[0]
	)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
