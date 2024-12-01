extends Resource
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
var _accept_input: AcceptInputCommand


func _init() -> void:
	_transition = TransitionCommand.new()
	_wait = WaitCommand.new()
	_accept_input = AcceptInputCommand.new()


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
func change_scene_to_file(room_path: String, enable_automatic_transitions: bool) -> void:
	if escoria.main and escoria.main.current_scene and escoria.main.current_scene.scene_file_path == room_path:
		escoria.logger.info(
			self,
			"Attempting to change scene to same scene as the current scene. Aborting."
		)
		if not Engine.is_editor_hint() \
				and (escoria.save_manager.is_loading_game or escoria.creating_new_game):
			escoria.main.current_scene.enabled_automatic_transitions = false
			escoria.room_manager.init_room(escoria.main.current_scene)
		return

	# We're changing scenes, so users shouldn't be able to do stuff during.
	escoria.inputs_manager.input_mode = escoria.inputs_manager.INPUT_NONE

	# Clear the event queue to remove other events (there could be duplicate
	# events in there so we avoid running these multiple times). Also sets a
	# flag indicating a changing scene and interrupts any other currently-running
	# events.
	escoria.event_manager.set_changing_scene(true)

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

	escoria.inputs_manager.hover_stack.clear()

	# Check if game scene was loaded
	if not escoria.game_scene:
		escoria.logger.error(
			self,
			"Failed loading game scene %s." % \
				ESCProjectSettingsManager.get_setting(
					ESCProjectSettingsManager.GAME_SCENE
				)
		)

	if escoria.main.current_scene \
			and escoria.game_scene.get_parent() == escoria.main.current_scene:
		escoria.main.current_scene.remove_child(escoria.game_scene)

	# Load room scene
	var res_room = escoria.resource_cache.get_resource(room_path)

	var room_scene = res_room.instantiate()
	if room_scene:
		if enable_automatic_transitions \
				and escoria.event_manager.get_running_event(
					escoria.event_manager.CHANNEL_FRONT
				) != null \
				and escoria.event_manager.get_running_event(
					escoria.event_manager.CHANNEL_FRONT
				).get_event_name() == escoria.event_manager.EVENT_ROOM_SELECTOR:
			room_scene.enabled_automatic_transitions = true
		else:
			room_scene.enabled_automatic_transitions = enable_automatic_transitions

		# If the game scene is already in the tree but not a child of the room
		# we remove it
		if escoria.game_scene.is_inside_tree() \
				and escoria.game_scene.get_parent() != room_scene:
			var game_parent = escoria.game_scene.get_parent()
			game_parent.remove_child(escoria.game_scene)

		room_scene.add_child(escoria.game_scene)
		room_scene.move_child(escoria.game_scene, 0)
		room_scene.game = escoria.game_scene
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
		escoria.logger.error(
			self,
			"Failed loading room scene %s." % room_path
		)


# Sanitize camera limits, add player node and set the global id to the
# name of this node if it's not set manually
#
# #### Parameters
#
# - room: The ESCRoom to be initialized for use.
func init_room(room: ESCRoom) -> void:
	if not is_instance_valid(room) || room == null:
		escoria.logger.error(
			self,
			"No valid room was specified for initialization."
		)

	if room.camera_limits.is_empty():
		room.camera_limits.push_back(Rect2())

	if room.camera_limits.size() == 1 and not room.camera_limits[0].has_area():
		for child in room.get_children():
			if child is ESCBackground:
				room.camera_limits[0] = \
					Rect2(0, 0, child.size.x, child.size.y)

	if Engine.is_editor_hint():
		return

	if room.has_node("game"):
		room.game = room.get_node("game")

	if room.game == null:
		room.game = escoria.game_scene
		room.add_child(room.game)
		room.move_child(room.game, 0)

	if room.is_run_directly:
		if escoria.main.current_scene == null:
			escoria.main.set_scene(room)

	# Register all navigationpolygons in the terrain
	if escoria.room_terrain != null:
		for n in escoria.room_terrain.get_children_navpolys():
			escoria.object_manager.register_terrain(
				ESCObject.new(
					n.name,
					n
				),
				room
			)

	# If the room node isn't at (0,0), the walk_stop function will offset the
	# player by the same number of pixels when they're at the terrain edge and
	# move them when it shouldn't.
	if room.position != Vector2(0,0):
		escoria.logger.error(
			self,
			"The room node's coordinates must be (0,0) instead of %s."
					% room.position
		)
	_perform_script_events(room)


# Performs the ESC script events "setup" and "ready", in this order, if they are
# present. Also manages automatic transitions.
#
# #### Parameters
#
# - room: The ESCRoom to be initialized for use.
# *Returns* 
func _perform_script_events(room: ESCRoom) -> int:
	# Used to track whether any yields have been executed before the call to
	# set_scene_finish.
	var yielded: bool = false

	if room.enabled_automatic_transitions \
			and not room.is_run_directly:

		var script_transition_out: ESCScriptBuilder = ESCScriptBuilder.new()
		script_transition_out \
			.add_event(escoria.event_manager.EVENT_TRANSITION_OUT, []) \
			.begin_block() \
				.add_command(
					_transition.get_command_name(),
					[
						ESCProjectSettingsManager.get_setting(
							ESCProjectSettingsManager.DEFAULT_TRANSITION
						),
						"out"
					]
				) \
				.add_command(_wait.get_command_name(), [0.1]) \
			.end_block()

		var script_transition_out_compiled = escoria.esc_compiler.compile(
			script_transition_out.build(),
			get_class())

		escoria.event_manager.queue_event(
			script_transition_out_compiled.events[escoria.event_manager.EVENT_TRANSITION_OUT],
			true
		)

#		var script_transition_out = escoria.esc_compiler.compile([
#			"%s%s" % [ESCEvent.PREFIX, escoria.event_manager.EVENT_TRANSITION_OUT],
#			"%s %s out" %
#				[
#					_transition.get_command_name(),
#					ESCProjectSettingsManager.get_setting(
#						ESCProjectSettingsManager.DEFAULT_TRANSITION
#					)
#				],
#			"%s 0.1" % _wait.get_command_name()
#		],
#		get_class()
#		)
#		escoria.event_manager.queue_event(
#			script_transition_out.events[escoria.event_manager.EVENT_TRANSITION_OUT],
#			true
#		)

		# Unpause the game if it was
		escoria.set_game_paused(false)

		# Wait for transition_out event to be done
		var rc = await escoria.event_manager.event_finished
		while rc[1] != escoria.event_manager.EVENT_TRANSITION_OUT:
			rc = await escoria.event_manager.event_finished
		if rc[0] != ESCExecution.RC_OK:
			return rc[0]

		yielded = true

	# With the room transitioned out, finish any room prep and run :setup if
	# it exists.
	if room.player_scene:
		if not is_instance_valid(room.player):
			room.player = room.player_scene.instantiate()
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

		#escoria.object_manager.get_object(escoria.object_manager.CAMERA).node.set_target(room.player)

	if room.global_id.is_empty():
		room.global_id = room.name


	# Manage player location at room start
	if room.player != null:
		var startloc := escoria.object_manager.get_start_location()
		if startloc != null:
			room.player.teleport(startloc)

	# We make sure 'room' is set as the new current_scene, but without making
	# it visible/the current scene tree.
	if not yielded:
		escoria.main.finish_current_scene_init(room)

	# Add new camera to scene being prepared.
	if room.player_camera:
		room.remove_child(room.player_camera)
		room.player_camera.queue_free()
	var new_player_camera: ESCCamera = escoria.resource_cache.get_resource(
		escoria.CAMERA_SCENE_PATH
	).instantiate()
	new_player_camera.register()
	room.player_camera = new_player_camera

	# We must first set the camera limits, and then worry about subsequent
	# player setup since it relies on this.
	escoria.main.set_camera_limits(0, room)

	# Add the camera in to the scene tree but don't make it active just yet.
	new_player_camera.enabled = false
	room.add_child(new_player_camera)
	room.move_child(new_player_camera, 0)

	if not escoria.save_manager.is_loading_game:
		var setup_event_added: bool = false

		# Run the setup event, if there is one.
		setup_event_added = _run_script_event(escoria.event_manager.EVENT_SETUP, room)

		if setup_event_added:
			# Wait for setup event to be done
			var rc = await escoria.event_manager.event_finished
			while rc[1] != escoria.event_manager.EVENT_SETUP:
				rc = await escoria.event_manager.event_finished
			if rc[0] != ESCExecution.RC_OK:
				return rc[0]

			yielded = true

	# As far as the event manager is concerned, we're done changing scenes and
	# so should resume allowing events to be queued and processed.
	escoria.event_manager.set_changing_scene(false)

	if room.player:
		escoria.object_manager.get_object(escoria.object_manager.CAMERA).node.set_target(room.player)

	# Conclude the call to set_scene (thankyouverymuch, coroutines), including
	# making the new room visible.
	escoria.main.set_scene_finish()

	# Hide main and pause menus
	escoria.game_scene.hide_main_menu()
	escoria.game_scene.unpause_game()

	# Maybe this is ok to put in set_scene_finish() above? But it might be a bit
	# confusing to not see the matching camera.current updates.
	new_player_camera.enabled = true
	new_player_camera.make_current()

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

	var transition_in_script: ESCScriptBuilder = ESCScriptBuilder.new()

	#var command_strings: PoolStringArray = []

	#command_strings.append("%s%s" % [ESCEvent.PREFIX, escoria.event_manager.EVENT_TRANSITION_IN])
	transition_in_script.add_event(escoria.event_manager.EVENT_TRANSITION_IN, [])
	transition_in_script.begin_block()

	if room.enabled_automatic_transitions \
			or (
				not room.enabled_automatic_transitions \
				and escoria.globals_manager.get_global( \
					escoria.room_manager.GLOBAL_FORCE_LAST_SCENE_NULL)
			):

		transition_in_script.add_command(_transition.get_command_name(), [
			ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.DEFAULT_TRANSITION
			),
			"in"
		])
#		command_strings.append("%s %s in" %
#			[
#				_transition.get_command_name(),
#				ESCProjectSettingsManager.get_setting(
#					ESCProjectSettingsManager.DEFAULT_TRANSITION
#				)
#			]
#		)

		transition_in_script.add_command(_wait.get_command_name(), [0.1])
		#command_strings.append("%s 0.1" % _wait.get_command_name())

	transition_in_script.add_command(_accept_input.get_command_name(), ["ALL"])
	#command_strings.append("%s ALL" % _accept_input.get_command_name())

	#var script_transition_in = escoria.esc_compiler.compile(command_strings, get_class())
	var script_transition_in = escoria.esc_compiler.compile(transition_in_script.build())

	escoria.event_manager.queue_event(
		script_transition_in.events[escoria.event_manager.EVENT_TRANSITION_IN]
	)

	if not escoria.current_state == escoria.GAME_STATE.LOADING:
		var ready_event_added: bool = false
		# Run the ready event, if there is one.
		ready_event_added = _run_script_event(escoria.event_manager.EVENT_READY, room)

		if ready_event_added:
			# Wait for ready event to be done
			var rc = await escoria.event_manager.event_finished
			while rc[1] != escoria.event_manager.EVENT_READY:
				rc = await escoria.event_manager.event_finished
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
	
	return ESCExecution.RC_OK


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
			self,
			"Queuing room script event %s " % event_name +
			"composed of %s statements."
					% room.compiled_script.events[event_name].get_num_statements_in_block()
		)
		escoria.event_manager.queue_event(room.compiled_script.events[event_name], true)
		return true
	else:
		return false
