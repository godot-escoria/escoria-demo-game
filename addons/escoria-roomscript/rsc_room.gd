extends ESCRoom
class_name RSCRoom, "res://addons/escoria-roomscript/rsc_room.svg"

# Lazily-constructed dictionary.
# Each key is a `ESCItem.global_id` and each value is an `ESCScript`.
var _room_script = null


func _enter_tree() -> void:
	# Ideally, we would call _parse_room_script() in _init(), but self.global_id
	# does not appear to be available at that point. The important thing is that
	# this is called before _ready().
	var path = find_script_file_for_room(self)
	_room_script = RSCRoomScriptFactory.from_path(path)

	# esc_room_manager.gd will only read the `ESCRoom.compiled_script`
	# field is `esc_script` is non-empty.
	esc_script = "non-empty-to-trick-esc-room-manager.esc"
	compiled_script = _room_script.get_events()


func _exit_tree() -> void:
	_room_script = null
	compiled_script = null


# Returns null if no RSCRoom can be found.
static func find_room_for_item(item: Node) -> RSCRoom:
	var node = item
	while node:
		node = node.get_parent()
		# Must use `as` instead of `is` when a class references itself:
		# https://github.com/godotengine/godot/issues/25252#issuecomment-586719227
		if node as RSCRoom:
			return node
	return null


# We cannot refer to an ESCItem in this file, or we will have a circular
# dependency, so we must take its global_id as an argument rather than the
# ESCItem itself.
func get_script_for_item_by_id(item_id: String) -> ESCScript:
	return _room_script.get_script_for_item(item_id)


static func find_script_file_for_room(room: RSCRoom) -> String:
	# For now, we enforce the convention that the name and Escoria global_id
	# should match, which must also be the name of the subfolder under rooms/,
	# as well as the name of the `.room` file. (If the rooms/ folder becomes
	# too large, we can revisit this.)
	var room_name = room.global_id
	var res = "res://rooms/%s/%s.room" % [room_name, room_name]
	escoria.logger.debug("room path: %s" % res)
	return res
