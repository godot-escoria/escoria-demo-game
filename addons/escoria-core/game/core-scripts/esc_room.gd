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
export(Array, Rect2) var camera_limits: Array = [Rect2()] setget set_camera_limits

# The editor debug display mode
export(int) var editor_debug_mode = EditorRoomDebugDisplay.NONE setget set_editor_debug_mode


# The player scene instance
var player


# The game scene instance
var game


# Start the random number generator when the camera limits should be displayed
func _enter_tree():
	if editor_debug_mode == EditorRoomDebugDisplay.CAMERA_LIMITS:
		randomize()


# Sanitize camera limits, add player node and set the global id to the
# name of this node if it's not set manually
func _ready():
	if camera_limits.empty():
		camera_limits.push_back(Rect2())
	if camera_limits.size() == 1 and camera_limits[0].has_no_area():
		camera_limits[0] = \
				Rect2(0, 0, $background.rect_size.x, $background.rect_size.y)
		
	if Engine.is_editor_hint():
		return
	
	game = $game
	
	if player_scene:
		player = player_scene.instance()
		add_child(player)
		escoria.object_manager.register_object(
			ESCObject.new(
				player.global_id,
				player
			),
			true
		)
		game.get_node("camera").set_target(player)
	
	for n in get_children():
		if n is ESCLocation and n.is_start_location:
			escoria.object_manager.register_object(
				ESCObject.new(n.name, n),
				true
			)
	
	if global_id.empty():
		global_id = name


# Draw the camera limits visualization if enabled
func _draw():
	if !Engine.is_editor_hint():
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
		var default_font = Control.new().get_font("font")
		
		draw_string(default_font, Vector2(camera_limits[i].position.x + 30, 
			camera_limits[i].position.y + 30), str(i), camera_limits_colors[i])


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
