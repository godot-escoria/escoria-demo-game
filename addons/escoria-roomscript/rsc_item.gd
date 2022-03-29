extends ESCItem
class_name RSCItem, "res://addons/escoria-roomscript/rsc_item.svg"


var _use_name_for_lookups = false

func _ready():
	var obj = escoria.object_manager.get_object(global_id)
	assert(obj)

	# If no esc_script is specified, try loading the item's behavior
	# from a .room file.
	if not esc_script:
		var room = RSCRoom.find_room_for_item(self)
		if room:
			var item_id = name if _use_name_for_lookups else global_id
			var script = room.get_script_for_item_by_id(item_id)
			obj.events = script.events


func _set_globalid_if_unset():
	if not global_id.empty():
		return

	var room = RSCRoom.find_room_for_item(self)
	if room && !room.global_id.empty() && !name.empty():
		global_id = room.global_id + '/' + name
		_use_name_for_lookups = true


# In ESCItem._ready(), _detect_children() is called *before*
# object_manager.register_object(), so we have a chance to
# modify the global_id field before anything reads it.
func _detect_children():
	_set_globalid_if_unset()
	._detect_children()
