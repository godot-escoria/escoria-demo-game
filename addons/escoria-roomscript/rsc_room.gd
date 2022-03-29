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
		# Must use `as` instead of `is` when a class references itself:
		# https://github.com/godotengine/godot/issues/25252#issuecomment-586719227
		if node as RSCRoom:
			return node
		node = node.get_parent()
	return null


# We cannot refer to an ESCItem in this file, or we will have a circular
# dependency, so we must take its global_id as an argument rather than the
# ESCItem itself.
func get_script_for_item_by_id(item_id: String) -> ESCScript:
	var script = _room_script.get_script_for_item(item_id)
	if script:
		return script
	else:
		return ESCScript.new()


# Resolves the item_id to its global id if this item was
# declared in the .room file; otherwise, returns `item_id`,
# assuming it is already a global id.
func resolve_item_id(item_id: String) -> String:
	if _room_script.has_script_for_item(item_id):
		return global_id + '/' + item_id
	else:
		return item_id


static func find_script_file_for_room(room: RSCRoom) -> String:
	# For now, we enforce the convention that the name and Escoria global_id
	# should match, which must also be the name of the subfolder under rooms/,
	# as well as the name of the `.room` file. (If the rooms/ folder becomes
	# too large, we can revisit this.)
	var room_id = room.global_id
	var room_dir = zero_pad_room_id(room_id)
	var res = "res://game/rooms/%s/%s.room" % [room_dir, room_id]
	escoria.logger.debug("room path: %s" % res)
	return res


# If `room_id` is `"room2"`, this returns `"room02"`.
static func zero_pad_room_id(room_id: String) -> String:
	var re = RegEx.new()
	var err = re.compile("^room(\\d+)$")
	assert(not err)

	var re_match = re.search(room_id)
	if re_match:
		var num = re_match.get_string(1)
		if num.length() == 1:
			return "room0" + num
	return room_id
