extends Object
class_name RSCRoomScript

# Events for the room, such as `:setup`.
var _events: ESCScript

# Each key is a `ESCItem.global_id` and each value is an `ESCScript`.
var _items: Dictionary


func _init(events: ESCScript, items: Dictionary) -> void:
	_events = events
	_items = items


func get_events() -> ESCScript:
	return _events


func get_script_for_item(item_id: String) -> ESCScript:
	var script = _items.get(item_id)
	if script:
		return script
	else:
		return null


func has_script_for_item(item_id: String) -> bool:
	return item_id in _items
