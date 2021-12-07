extends Object
class_name ESCRoomManager


# Reserved globals which can not be overridden; prefixed with "GLOBAL_"
#
# Contains the global_id of previous room
const GLOBAL_LAST_SCENE = "ESC_LAST_SCENE"

# If true, ESC_LAST_SCENE is not considered for automatic transitions
const GLOBAL_FORCE_LAST_SCENE_NULL = "FORCE_LAST_SCENE_NULL"

const GLOBAL_ANIMATION_RESOURCES = "ANIMATION_RESOURCES"

# Contains the global_id of the current room
const GLOBAL_CURRENT_SCENE = "ESC_CURRENT_SCENE"

# Dict of the reserved globals to register and their initial values.
const RESERVED_GLOBALS = {
	GLOBAL_LAST_SCENE: "",
	GLOBAL_FORCE_LAST_SCENE_NULL: false,
	GLOBAL_ANIMATION_RESOURCES: {},
	GLOBAL_CURRENT_SCENE: ""
}


# Registers all reserved global flags for use.
func register_reserved_globals() -> void:
	for key in RESERVED_GLOBALS:
		escoria.globals_manager.register_reserved_global( \
			key, 
			RESERVED_GLOBALS[key])


# Sanitize camera limits, add player node and set the global id to the
# name of this node if it's not set manually
func init_room(room: ESCRoom) -> void:
	if not is_instance_valid(room) || room == null:
		escoria.logger.report_errors(
			"ESCRoomManager.init_room: No valid room specified",
			[
				"No valid room was specified for initialization."
			]
		)
		
	if room.camera_limits.empty():
		room.camera_limits.push_back(Rect2())

	if room.camera_limits.size() == 1 and room.camera_limits[0].has_no_area():
		for child in room.get_children():
			if child is ESCBackground:
				room.camera_limits[0] = \
					Rect2(0, 0, child.rect_size.x, child.rect_size.y)
		
	if Engine.is_editor_hint():
		return
	
	if room.has_node("game"):
		room.game = room.get_node("game")

	if room.game == null:
		room.game = escoria.game_scene
		room.add_child(room.game)
		room.move_child(room.game, 0)
	
	# Determine whether this room was run from change_scene or directly
	if escoria.main.has_node(room.name):
		room.is_run_directly = false
	else:
		room.is_run_directly = true
		if escoria.main.current_scene == null:
			escoria.main.set_scene(room)
	
	if room.player_scene:
		room.player = room.player_scene.instance()
		room.add_child(room.player)
		escoria.object_manager.register_object(
			ESCObject.new(
				room.player.global_id,
				room.player
			),
			true
		)
		if escoria.globals_manager.has(
			escoria.room_manager.GLOBAL_ANIMATION_RESOURCES
		):
			var animations = escoria.globals_manager.get_global(
				escoria.room_manager.GLOBAL_ANIMATION_RESOURCES
			)
			
			if room.player.global_id in animations and \
					ResourceLoader.exists(animations[room.player.global_id]):
				room.player.animations = ResourceLoader.load(
					animations[room.player.global_id]
				)
				room.player.update_idle()
		escoria.object_manager.get_object("_camera").node.set_target(room.player)
	
	if room.global_id.empty():
		room.global_id = room.name
	
	# Manage player location at room start
	if room.player != null \
			and escoria.object_manager.get_start_location() != null:
		room.player.teleport(escoria.object_manager.get_start_location().node)
	
	_perform_script_events(room)


# Performs the ESC script events "setup" and "ready", in this order, if they are
# present. Also manages automatic transitions.
func _perform_script_events(room: ESCRoom):
	if room.esc_script and escoria.event_manager.is_channel_free("_front") \
			or (
				not escoria.event_manager.is_channel_free("_front") and \
				not escoria.event_manager.get_running_event(
					"_front"
				).name == "load"
			):
			
		# If the room was loaded from change_scene and automatic transitions
		# are not disabled, do the transition out now
		if room.enabled_automatic_transitions \
				and not room.is_run_directly \
				and not room.exited_previous_room:
			var script_transition_out = escoria.esc_compiler.compile([
				":transition_out",
				"transition %s out" % ProjectSettings.get_setting(
					"escoria/ui/default_transition"
				),
				"wait 0.1"
			])
			escoria.event_manager.queue_event(
				script_transition_out.events['transition_out']
			)
			
			# Unpause the game if it was
			escoria.set_game_paused(false)
			
			# Wait for transition_out event to be done
			var rc = yield(escoria.event_manager, "event_finished")
			while rc[1] != "transition_out":
				rc = yield(escoria.event_manager, "event_finished")
			if rc[0] != ESCExecution.RC_OK:
				return rc[0]
			
			# Hide main and pause menus
			escoria.game_scene.hide_main_menu()
			escoria.game_scene.unpause_game()
			
		# Run the setup event
		_run_script_event("setup", room)
		
		if room.enabled_automatic_transitions \
				or (
					not room.enabled_automatic_transitions \
					and escoria.globals_manager.get_global( \
						escoria.room_manager.GLOBAL_FORCE_LAST_SCENE_NULL)
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
		ready_event_added = _run_script_event("ready", room)
		
		if ready_event_added:
			# Wait for ready event to be done
			var rc = yield(escoria.event_manager, "event_finished")
			while rc[1] != "ready":
				rc = yield(escoria.event_manager, "event_finished")
			if rc[0] != ESCExecution.RC_OK:
				return rc[0]
		
		# Now that :ready is finished, if FORCE_LAST_SCENE_NULL was true, reset it 
		# to false
		if escoria.globals_manager.get_global( \
			escoria.room_manager.GLOBAL_FORCE_LAST_SCENE_NULL):

			escoria.globals_manager.set_global(
				escoria.room_manager.GLOBAL_FORCE_LAST_SCENE_NULL, 
				false, 
				true
			)
			escoria.globals_manager.set_global(
				escoria.room_manager.GLOBAL_LAST_SCENE,
				escoria.main.current_scene.global_id \
						if escoria.main.current_scene != null else "", 
				true
			)
		
		# Make the room's global ID available for use in ESC script.
		escoria.globals_manager.set_global(
			escoria.room_manager.GLOBAL_CURRENT_SCENE,
			escoria.main.current_scene.global_id \
					if escoria.main.current_scene != null else "", 
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
func _run_script_event(event_name: String, room: ESCRoom):
	if not room.esc_script:
		return false
	if room.compiled_script == null:
		room.compiled_script = \
			escoria.esc_compiler.load_esc_file(room.esc_script)
	
	if room.compiled_script.events.has(event_name):
		escoria.logger.debug(
			"esc_room:_run_script_event", 
			[
				"Queuing room script event %s" % event_name,
				"Composed of %s statements" % 
					str(room.compiled_script.events[event_name].statements.size())
			]
		)
		escoria.event_manager.queue_event(room.compiled_script.events[event_name])
		return true
	else:
		return false
