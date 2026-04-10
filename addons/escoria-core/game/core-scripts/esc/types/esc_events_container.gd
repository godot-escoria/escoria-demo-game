## Container for storing events in Escoria, providing a consistent way to provide
## visibility and access to events.
extends RefCounted
class_name ESCEventsContainer


## The list of events being tracked.
var events: Array = []


## Adds an event to the container.[br]
##[br]
## #### Parameters[br]
##[br]
## - event: the event to be stored
func add(event) -> void:
	events.append(event)


## Determines whether the specified events list contains an event with the[br]
## specified event name and event target, e.g. `:give "filled_out_form"`[br]
##[br]
## #### Parameters[br]
##[br]
## - event_name: the event name to search for[br]
## - event_target: the target for the specified event to check; may be null[br]
##[br]
## *Returns* true iff events contains an event matching both event_name and event_target
func has_event_with_target(event_name: String, event_target = null) -> bool:
	return is_instance_valid(get_event_with_target(event_name, event_target))


## Returns the event matching the specified event name and target, e.g. `:give "filled_out_form"`[br]
## if it exists; returns null otherwise.[br]
##[br]
## #### Parameters[br]
##[br]
## - event_name: the event name to search for[br]
## - event_target: the target for the specified event to check; may be null[br]
##[br]
## *Returns* the event in `events` iff `events` contains an event matching both `event_name` and `event_target`;[br]
## returns null otherwise.
func get_event_with_target(event_name: String, event_target = null):
	for event in events:
		if event.get_event_name() == event_name:
			if event_target:
				if event.get_target_name() == event_target:
					return event

				return null
			else:
				return event

	return null
