# A room in an Escora based game
tool
extends Node2D
class_name ESCRoom, "res://addons/escoria-core/design/esc_room.svg"


# Emitted when room has finished ":setup" event.
signal room_setup_done

# Emitted when room has finished ":ready" event.
signal room_ready_done


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

# The game scene instance
var game

# Compiled ESCScript
var compiled_script: ESCScript

# Whether automatic transition are enabled or not
var enabled_automatic_transitions = true

# Whether this room was run directly with Play Scene (F6)
var is_run_directly = false

# Whether this room was accessed from an exit in a previous room
var exited_previous_room = false


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
	
	if has_node("game"):
		game = $game
	if game == null:
		game = escoria.game_scene
		add_child(game)
		move_child(game, 0)
	
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
	
	# Determine whether this room was run from change_scene or directly
	if escoria.main.has_node(name):
		is_run_directly = false
	else:
		is_run_directly = true
	
	# Manage player location at room start
	if player != null \
			and escoria.object_manager.get_start_location() != null:
		player.teleport(escoria.object_manager.get_start_location().node)
	
	perform_script_events()


# Performs the ESC script events "setup" and "ready", in this order, if they are
# present. Also manages automatic transitions.
func perform_script_events():
	if esc_script and escoria.event_manager._running_event == null \
			or (escoria.event_manager._running_event != null \
			and escoria.event_manager._running_event.name != "load"):
		
		# If the room was loaded from change_scene and automatic transitions
		# are not disabled, do the transition out now
		if enabled_automatic_transitions \
				and not is_run_directly \
				and not exited_previous_room:
			var script_transition_out = escoria.esc_compiler.compile([
				":transition_out",
				"transition %s out" % ProjectSettings.get_setting(
					"escoria/ui/default_transition"
				),
				"hide_menu main"
			])
			escoria.event_manager.queue_event(
				script_transition_out.events['transition_out']
			)
			
		# Run the setup event
		_run_script_event("setup")
		
		if enabled_automatic_transitions \
				or (
					not enabled_automatic_transitions \
					and escoria.globals_manager.get_global("BYPASS_LAST_SCENE")
				):
			var script_transition_in = escoria.esc_compiler.compile([
				":transition_in",
				"transition %s in" % ProjectSettings.get_setting(
					"escoria/ui/default_transition"
				),
				"wait 0.1"
			])
			escoria.event_manager.queue_event(
				script_transition_in.events['transition_in']
			)
		
		var ready_event_added: bool = false
		# Run the ready event, if there is one.
		if escoria.event_manager._running_event == null \
				or (escoria.event_manager._running_event != null \
				and escoria.event_manager._running_event.name != "load"):
			ready_event_added = _run_script_event("ready")
		
		if ready_event_added:
			# Wait for ready event to be done
			var rc = yield(escoria.event_manager, "event_finished")
			while rc[1] != "ready":
				rc = yield(escoria.event_manager, "event_finished")
			if rc[0] != ESCExecution.RC_OK:
				return rc[0]
		
		# Now that :ready is finished, if BYPASS_LAST_SCENE was true, reset it 
		# to false and set ESC_LAST_SCENE to current scene
		if escoria.globals_manager.get_global("BYPASS_LAST_SCENE"):
			escoria.globals_manager.set_global(
				"BYPASS_LAST_SCENE", 
				false, 
				true
			)
			escoria.globals_manager.set_global(
				"ESC_LAST_SCENE",
				escoria.main.current_scene.global_id, 
				true
			)


# Runs the script event from the script attached, if any.
#
# #### Parameters
#
# - event_name: the name of the event to run
#
# *Returns* true if the event was correctly added. Will be false if the event
# does not exist in the script.
func _run_script_event(event_name: String):
	if !esc_script:
		return false
	if compiled_script == null:
		compiled_script = escoria.esc_compiler.load_esc_file(esc_script)
	
	if compiled_script.events.has(event_name):
		escoria.logger.debug(
			"esc_room:_run_script_event", 
			[
				"Queuing room script event %s" % event_name,
				"Composed of %s statements" % str(compiled_script.events[event_name].statements.size())
			]
		)
		escoria.event_manager.queue_event(compiled_script.events[event_name])
		return true
	else:
		return false


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



