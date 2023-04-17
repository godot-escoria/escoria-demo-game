# A room in an Escora based game
tool
extends Node2D
class_name ESCRoom, "res://addons/escoria-core/design/esc_room.svg"


# Debugging displays for a room
# NONE: No debug display
# CAMERA_LIMITS: Display the camera limits
enum EditorRoomDebugDisplay {
	NONE,
	CAMERA_LIMITS
}


# The global id of this room
export(String) var global_id = ""

# The ESC script of this room
export(String, FILE, "*.esc") var esc_script = ""

# The player inside this scene
export(PackedScene) var player_scene

# The camera limits available in this room
export(Array, Rect2) var camera_limits: Array \
	= [Rect2()] setget set_camera_limits

# The editor debug display mode
export(EditorRoomDebugDisplay) var editor_debug_mode \
	= EditorRoomDebugDisplay.NONE setget set_editor_debug_mode


# The player scene instance
var player

# The player camera
var player_camera: ESCCamera

# The game scene instance
var game

# Compiled ESCScript
var compiled_script: ESCScript

# Whether automatic transition are enabled or not
var enabled_automatic_transitions = true

# Whether this room was run directly with Play Scene (F6)
var is_run_directly = false


# Start the random number generator when the camera limits should be displayed
func _enter_tree():
	if editor_debug_mode == EditorRoomDebugDisplay.CAMERA_LIMITS:
		randomize()


# Sanitize camera limits, add player node and set the global id to the
# name of this node if it's not set manually
func _ready():
	# Might as well just check here.
	if get_parent() == get_tree().root \
			and ESCProjectSettingsManager.get_setting(
				"application/run/main_scene"
			) != self.filename:
		is_run_directly = true

	if Engine.is_editor_hint():
		_connect_location_nodes()
		_validate_start_locations()
		return
	
	# If room has no ESCBackground child, add one
	var found_escbackground: bool = false
	for child in get_children():
		if child is ESCBackground:
			found_escbackground = true
	if not found_escbackground:
		var esc_bg = ESCBackground.new()
		esc_bg.name = "background"
		add_child(esc_bg)
		move_child(esc_bg, 0)

	escoria.room_manager.init_room(self)


# Draw the camera limits visualization if enabled
func _draw():
	if not Engine.is_editor_hint():
		return
	if editor_debug_mode == EditorRoomDebugDisplay.NONE:
		return

	var camera_limits_colors: Array = [
		ColorN("red"), ColorN("blue"), ColorN("green")
	]

	# If there are more camera limits than colors defined for them, add more.
	if camera_limits.size() > camera_limits_colors.size():
		for i in camera_limits.size() - camera_limits_colors.size():
			camera_limits_colors.push_back(Color(randf(), randf(), randf(), 1.0))

	# Draw lines for camera limits
	for i in camera_limits.size():
		draw_rect(camera_limits[i], camera_limits_colors[i], false, 10.0)
		var temp_control = Control.new()
		var default_font = temp_control.get_font("font")
		temp_control.queue_free()

		draw_string(default_font, Vector2(camera_limits[i].position.x + 30,
			camera_limits[i].position.y + 30), str(i), camera_limits_colors[i])


# Listen for any signals from ESCLocation indicating that the is_start_location attribute
# has been set/unset in order to update start location validation.
func _connect_location_nodes() -> void:
	_connect_location_nodes_in_tree(self)


func _connect_location_nodes_in_tree(node: Node):
	for n in node.get_children():
		if n is ESCLocation:
			if not n.is_connected("is_start_location_set", self, "_validate_start_locations"):
				n.connect("is_start_location_set", self, "_validate_start_locations")

		if n.get_child_count() > 0:
			_connect_location_nodes_in_tree(n)


# Validate that we only have one start location for this scene. If we don't, call it out in the
# scene tree via configuration warnings.
#
# We may have to ignore a node if it's being removed/deleted from the scene tree.
func _validate_start_locations(to_ignore: ESCLocation = null):
	var esc_locations: Array = _find_esc_locations(self)
	var num_start_locations: int = 0

	for n in esc_locations:
		if n == to_ignore:
			continue

		num_start_locations += 1 if n.is_start_location else 0

	for n in esc_locations:
		if n == to_ignore:
			continue

		n.set_multiple_locations_exist(n.is_start_location and num_start_locations > 1)


func _find_esc_locations(node: Node) -> Array:
	var esc_locations: Array = []

	for n in node.get_children():
		if n is ESCLocation:
			esc_locations.append(n)

		if n.get_child_count() > 0:
			esc_locations.append_array(_find_esc_locations(n))

	return esc_locations


# Set the camera limits
#
# #### Parameters
#
# - p_camera_limits: An array of Rect2Ds as camera limits
func set_camera_limits(p_camera_limits: Array) -> void:
	camera_limits = p_camera_limits
	update()


# Set the editor debug mode
#
# #### Parameters
#
# - p_editor_debug_mode: The debug mode to set for the room
func set_editor_debug_mode(p_editor_debug_mode: int) -> void:
	editor_debug_mode = p_editor_debug_mode
	update()

