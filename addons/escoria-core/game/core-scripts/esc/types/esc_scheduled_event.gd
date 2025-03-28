## Represents an event that is scheduled to run sometime in the future.
extends RefCounted
class_name ESCScheduledEvent


## The event to run when timeout is reached.
var event

## The number of seconds until the event is to be run.
var timeout: float

## The target object.
var object: String


# Create a new scheduled event
func _init(p_event, p_timeout: float, p_object: String):
	self.event = p_event
	self.timeout = p_timeout
	self.object = p_object


## Returns a `Dictionary` containing relevant data for serialization.
func exported() -> Dictionary:
	var exported_dict: Dictionary = {}
	exported_dict.class = "ESCScheduledEvent"
	exported_dict.event = event.exported()
	exported_dict.timeout = timeout
	exported_dict.object = object
	return exported_dict


## Runs the event.[br]
##[br]
## **Returns** the event's resulting execution code (see `ESCExecution`).
func run() -> int:
	return await event.run()
