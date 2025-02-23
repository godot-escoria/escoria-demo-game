# Couple of Event name and a flags combination value
# to be used when forcing a specific flag for a given event.
extends Resource
class_name ESCEventFlagForce

# Event name (usually a verb)
var _event_name: String:
	get = get_event_name

# Flags combination to force.
# Obtained with operator |= new_value
var _flags: int:
	get = get_flags


func _init(event_name: String, flags: int):
	_event_name = event_name
	_flags = flags


func get_event_name() -> String:
	return _event_name


func get_flags() -> int:
	return _flags
