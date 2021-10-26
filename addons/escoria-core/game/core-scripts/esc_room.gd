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
export(EditorRoomDebugDisplay) var editor_debug_mode = EditorRoomDebugDisplay.NONE setget set_editor_debug_mode


# The player scene instance
var player


# The game scene instance
var game


# Compiled ESCScript
var compiled_script: ESCScript 


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
	if game == null:
		game = escoria.game_scene
		add_child(game)
		move_child(game, 0)
	
	if escoria.main.current_scene == null:
		escoria.main.set_scene(self)
	
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
		escoria.object_manager.get_object("_camera").node.set_target(player)
	
	for n in get_children():
		if n is ESCLocation and n.is_start_location:
			escoria.object_manager.register_object(
				ESCObject.new(n.name, n),
				true
			)
	
	if global_id.empty():
		global_id = name
		
	if esc_script:
		run_script_event("setup")
		var rc = yield(escoria.event_manager, "event_finished")
		while rc[1] != "setup":
			rc = yield(escoria.event_manager, "event_finished")
		if rc[0] != ESCExecution.RC_OK:
			return rc[0]
		
		if (escoria.globals_manager.get_global("ESC_LAST_SCENE") == null \
			or escoria.globals_manager.get_global("ESC_LAST_SCENE").empty()) \
			and player != null \
			and escoria.object_manager.get_start_location() != null:
			player.teleport(escoria.object_manager.get_start_location().node)
			
		
		escoria.main.scene_transition.transition()
		yield(escoria.main.scene_transition, "transition_done")
	
		run_script_event("ready")
		rc = yield(escoria.event_manager, "event_finished")
		while rc[1] != "ready":
			rc = yield(escoria.event_manager, "event_finished")
		if rc[0] != ESCExecution.RC_OK:
			return rc[0]

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


# Runs the script event from the script attached, if any
#
# #### Parameters
#
# - event_name: the name of the event to run
func run_script_event(event_name: String):
	if !esc_script:
		return
	if compiled_script == null:
		compiled_script = escoria.esc_compiler.load_esc_file(esc_script)
	
	if compiled_script.events.has(event_name):
		escoria.event_manager.queue_event(compiled_script.events[event_name])
