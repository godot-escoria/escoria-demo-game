## Represents a compiled ASHES script.
extends Resource
class_name ESCScript


## The events registered with the script.
var events: ESCEventsContainer = ESCEventsContainer.new()


##############
# New interpreter stuff
var parsed_events = []


## The name of the ASHES file parsed for this script, if this script was in fact
## loaded from a file (as opposed to being from an internal string).
var filename: String = ""

##############


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
	return events.has_event_with_target(event_name, event_target)


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
	return events.get_event_with_target(event_name, event_target)
