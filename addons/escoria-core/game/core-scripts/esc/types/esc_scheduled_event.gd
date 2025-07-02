## Represents an event that is scheduled to run sometime in the future.
extends RefCounted
class_name ESCScheduledEvent


## The event to run when timeout is reached.
var event

## The number of seconds until the event is to be run.
var timeout: float

## The target object.
var object: String

## Creates a new scheduled event.[br]
## [br]
## #### Parameters[br]
## [br]
## - p_event: The event to schedule.[br]
## - p_timeout: The number of seconds until the event is run.[br]
## - p_object: The target object.
func _init(p_event: ESCGrammarStmts.Event, p_timeout: float, p_object: String):
	self.event = p_event
	self.timeout = p_timeout
	self.object = p_object


## Returns a `Dictionary` containing relevant data for serialization.
func exported() -> Dictionary:
	var exported_dict: Dictionary = {}
	exported_dict.class = "ESCScheduledEvent"
	exported_dict.event_name = event.get_name().get_lexeme()
	exported_dict.event_filename = event.get_name().get_filename()
	exported_dict.timeout = timeout
	exported_dict.object = object
	return exported_dict


## TODO: THIS IS NO LONGER USED AS EVENT IS NOW RUN BY ASHES INTERPRETER. THIS MAY BE REMOVED IN THE FUTURE.[br]
## Runs the event.[br]
##[br]
## **Returns** the event's resulting execution code (see `ESCExecution`).
func run() -> int:
	return await event.run()
