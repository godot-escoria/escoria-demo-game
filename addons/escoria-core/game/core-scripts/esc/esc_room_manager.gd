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


# ESC commands kept around for references to their command names.
var _transition: TransitionCommand
var _wait: WaitCommand


func _init() -> void:
	_transition = TransitionCommand.new()
	_wait = WaitCommand.new()


# Registers all reserved global flags for use.
func register_reserved_globals() -> void:
	for key in RESERVED_GLOBALS:
		escoria.globals_manager.register_reserved_global( \
			key,
			RESERVED_GLOBALS[key])


# Performs the actions needed in order to change the current scene to the one
# specified by room_path.
#
# #### Parameters
#
# - room_path: Node path to the room that is to become the new current room.
# - enable_automatic_transitions: Whether to play the transition between rooms
#	automatically or to leave the responsibility to the developer.
func change_scene(room_path: String, enable_automatic_transitions: bool) -> void:
	# Clear the event queue to remove other events (there could be duplicate
	# events in there so we avoid running these multiple times)
	escoria.event_manager.clear_event_queue()

	# If FORCE_LAST_SCENE_NULL is true, force ESC_LAST_SCENE to empty
	if escoria.globals_manager.get_global( \
		GLOBAL_FORCE_LAST_SCENE_NULL):

		escoria.globals_manager.set_global(
			GLOBAL_LAST_SCENE,
			null,
			true
		)
	elif escoria.main.current_scene:
		# If FORCE_LAST_SCENE_NULL is false, set ESC_LAST_SCENE = current roomid
		escoria.globals_manager.set_global(
			GLOBAL_LAST_SCENE,
			escoria.main.current_scene.global_id,
			true
		)

	if escoria.dialog_player:
		escoria.dialog_player.interrupt()

	escoria.inputs_manager.clear_stack()

	# Check if game scene was loaded
	if not escoria.game_scene:
		escoria.logger.report_errors(
			"ESCRoomManager.change_scene: Failed loading game scene",
			[
				"Failed loading scene %s" % \
						escoria.project_settings_manager.get_setting(
							escoria.project_settings_manager.GAME_SCENE
							)
			]
		)

	# Load room scene
	var res_room = escoria.resource_cache.get_resource(room_path)

	var room_scene = res_room.instance()
	if room_scene:
		if enable_automatic_transitions \
				and escoria.event_manager.get_running_event(escoria.event_manager.CHANNEL_FRONT) != null \
				and escoria.event_manager.get_running_event(escoria.event_manager.CHANNEL_FRONT).name \
				== escoria.event_manager.EVENT_ROOM_SELECTOR:
			room_scene.enabled_automatic_transitions = true
		else:
			room_scene.enabled_automatic_transitions = enable_automatic_transitions

		escoria.main.set_scene(room_scene)

		# We know the scene has been loaded. Make its global ID available for
		# use by ESC script.
		escoria.globals_manager.set_global(
			escoria.room_manager.GLOBAL_CURRENT_SCENE,
			room_scene.global_id,
			true
		)

		# Clear queued resources
		escoria.resource_cache.clear()

		escoria.inputs_manager.hotspot_focused = ""
	else:
		escoria.logger.report_errors(
			"ESCRoomManager.change_scene: Failed loading room scene",
			[
				"Failed loading scene %s" % room_path
			]
		)


# Sanitize camera limits, add player node and set the global id to the
# name of this node if it's not set manually
#
# #### Parameters
#
# - room: The ESCRoom to be initialized for use.
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

	_perform_script_events(room)


# Performs the ESC script events "setup" and "ready", in this order, if they are
# present. Also manages automatic transitions.
#
# #### Parameters
#
# - room: The ESCRoom to be initialized for use.
func _perform_script_events(room: ESCRoom) -> void:
	# Used to track whether any yields have been executed before the call to
	# set_scene_finish.
	var yielded: bool = false

	if room.enabled_automatic_transitions \
			and not room.is_run_directly:
		var script_transition_out = escoria.esc_compiler.compile([
			"%s%s" % [ESCEvent.PREFIX, escoria.event_manager.EVENT_TRANSITION_OUT],
			"%s %s out" %
				[
					_transition.get_command_name(),
					escoria.project_settings_manager.get_setting(
						escoria.project_settings_manager.DEFAULT_TRANSITION
					)
				],
			"%s 0.1" % _wait.get_command_name()
		],
		get_class()
		)
		escoria.event_manager.queue_event(
			script_transition_out.events[escoria.event_manager.EVENT_TRANSITION_OUT]
		)

		# Unpause the game if it was
		escoria.set_game_paused(false)

		# Wait for transition_out event to be done
		var rc = yield(escoria.event_manager, "event_finished")
		while rc[1] != escoria.event_manager.EVENT_TRANSITION_OUT:
			rc = yield(escoria.event_manager, "event_finished")
		if rc[0] != ESCExecution.RC_OK:
			return rc[0]

		yielded = true

		# Hide main and pause menus
		escoria.game_scene.hide_main_menu()
		escoria.game_scene.unpause_game()

	# With the room transitioned out, finish any room prep and run :setup if
	# it exists.
	if escoria.main.current_scene \
			and escoria.game_scene.get_parent() == escoria.main.current_scene:
		escoria.main.current_scene.remove_child(escoria.game_scene)

	# If the game scene is already in the tree but not a child of the room
	# we remove it
	if escoria.game_scene.is_inside_tree() \
			and escoria.game_scene.get_parent() != room:
		var game_parent = escoria.game_scene.get_parent()
		game_parent.remove_child(escoria.game_scene)

	room.add_child(escoria.game_scene)
	room.move_child(escoria.game_scene, 0)
	room.game = escoria.game_scene
	
	# We must first et the camera limits, and then worry about subsequent
	# player setup since it relies on this.
	escoria.main.set_camera_limits(0, room)

	if room.player_scene:
		room.player = room.player_scene.instance()
		room.add_child(room.player)
		escoria.object_manager.register_object(
			ESCObject.new(
				room.player.global_id,
				room.player
			),
			room,
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

		escoria.object_manager.get_object(escoria.object_manager.CAMERA).node.set_target(room.player)

	if room.global_id.empty():
		room.global_id = room.name

	# Manage player location at room start
	if room.player != null \
			and escoria.object_manager.get_start_location() != null:
		room.player.teleport(escoria.object_manager.get_start_location().node)

	var setup_event_added: bool = false
	# Run the setup event, if there is one.
	setup_event_added = _run_script_event(escoria.event_manager.EVENT_SETUP, room)

	if setup_event_added:
		# Wait for setup event to be done
		var rc = yield(escoria.event_manager, "event_finished")
		while rc[1] != escoria.event_manager.EVENT_SETUP:
			rc = yield(escoria.event_manager, "event_finished")
		if rc[0] != ESCExecution.RC_OK:
			return rc[0]

		yielded = true

	if not yielded:
		escoria.main.finish_current_scene_init(room)

	escoria.main.set_scene_finish()

	# We know the scene has been loaded. Make its global ID available for
	# use by ESC script.
	escoria.globals_manager.set_global(
		escoria.room_manager.GLOBAL_CURRENT_SCENE,
		room.global_id,
		true
	)

	# Clear queued resources
	escoria.resource_cache.clear()

	escoria.inputs_manager.hotspot_focused = ""

	if room.enabled_automatic_transitions \
			or (
				not room.enabled_automatic_transitions \
				and escoria.globals_manager.get_global( \
					escoria.room_manager.GLOBAL_FORCE_LAST_SCENE_NULL)
			):
		var script_transition_in = escoria.esc_compiler.compile([
			"%s%s" % [ESCEvent.PREFIX, escoria.event_manager.EVENT_TRANSITION_IN],
			"%s %s in" %
				[
					_transition.get_command_name(),
					escoria.project_settings_manager.get_setting(
						escoria.project_settings_manager.DEFAULT_TRANSITION
					)
				],
			"%s 0.1" % _wait.get_command_name()
		],
		get_class()
		)
		escoria.event_manager.queue_event(
			script_transition_in.events[escoria.event_manager.EVENT_TRANSITION_IN]
		)

	var ready_event_added: bool = false
	# Run the ready event, if there is one.
	ready_event_added = _run_script_event(escoria.event_manager.EVENT_READY, room)

	if ready_event_added:
		# Wait for ready event to be done
		var rc = yield(escoria.event_manager, "event_finished")
		while rc[1] != escoria.event_manager.EVENT_READY:
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
# - room: The ESCRoom to be initialized for use.
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
					room.compiled_script.events[event_name].statements.size()
			]
		)
		escoria.event_manager.queue_event(room.compiled_script.events[event_name])
		return true
	else:
		return false
