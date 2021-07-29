# An event that is scheduled to run later
extends Object
class_name ESCScheduledEvent


# Event to run when timeout is reached
var event: ESCEvent


# The number of seconds until the event is run
var timeout: float


# Create a new scheduled event
func _init(p_event: ESCEvent, p_timeout: float):
	self.event = p_event
	self.timeout = p_timeout


# Run the event
#
# **Returns** The execution code
func run() -> int:
	return event.run()
