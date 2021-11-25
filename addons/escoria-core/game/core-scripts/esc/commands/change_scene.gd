# `change_scene path [enable_automatic_transition] [run_events]`
#
# Switches the current scene to another scene
#
# **Parameters**
#
# - *path*: Path of the new scene
# - *enable_automatic_transition*: Automatically transition to the new scene 
#   (default: `true`)
# - *run_events*: Run the standard ESC events of the new scene (default: `true`)
#
# @ESC
extends ESCBaseCommand
class_name ChangeSceneCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_STRING, TYPE_BOOL, TYPE_BOOL],
		[null, true, true]
	)
	
	
# Validate wether the given arguments match the command descriptor
func validate(arguments: Array) -> bool:
	if not ResourceLoader.exists(arguments[0]):
		escoria.logger.report_errors(
			"change_scene: Invalid scene", 
			["Scene %s was not found" % arguments[0]]
		)
		return false
	if not ResourceLoader.exists(
		ProjectSettings.get_setting("escoria/ui/game_scene")
	):
		escoria.logger.report_errors(
			"change_scene: Game scene not found", 
			[
				"The path set in 'ui/game_scene' was not found: %s" % \
						ProjectSettings.get_setting("escoria/ui/game_scene")
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.logger.info(
		"Changing scene to %s (enable_automatic_transition = %s, run_events = %s)" % [
		command_params[0],	# scene file
		command_params[1],	# enable_automatic_transition
		command_params[2]	# run_events
	])
	
	# Clear the event queue to remove other events (there could be duplicate
	# events in there so we avoid running these multiple times)
	escoria.event_manager.clear_event_queue()
	
	var exited_previous_room = false
	
	# If auto transition is enabled, try to determine whether we just exited a 
	# room previously, so that we must play the auto transition out or not.
	# This must happen if ESC_LAST_SCENE is set, or if we're running an 
	# exit_scene event. Also room selector actions require the transition.
	if command_params[1] \
			and (
				not escoria.globals_manager.get_global("ESC_LAST_SCENE").empty()
				or (
					escoria.event_manager.get_running_event("_front").name \
						in ["newgame", "exit_scene", "room_selector"]
						and escoria.globals_manager.get_global(
							"ESC_LAST_SCENE"
						).empty()
					)
				):
		exited_previous_room = true
		var transition_id = escoria.main.scene_transition.transition(
			"", 
			ESCTransitionPlayer.TRANSITION_MODE.OUT
		)
		escoria.logger.debug(
			"Awaiting transition %s (out) to be finished." % str(transition_id)
		)
		yield(escoria.main.scene_transition, "transition_done")
		
	# Hide main and pause menus
	escoria.game_scene.hide_main_menu()
	escoria.game_scene.unpause_game()

	# If FORCE_LAST_SCENE_NULL is true, force ESC_LAST_SCENE to empty
	if escoria.globals_manager.get_global("FORCE_LAST_SCENE_NULL"):
		escoria.globals_manager.set_global(
			"ESC_LAST_SCENE", 
			null, 
			true
		)
	elif escoria.main.current_scene:
		# If FORCE_LAST_SCENE_NULL is false, set ESC_LAST_SCENE = current roomid
		escoria.globals_manager.set_global(
			"ESC_LAST_SCENE", 
			escoria.main.current_scene.global_id, 
			true
		)
	
	if escoria.dialog_player:
		escoria.dialog_player.interrupt()
	
	escoria.inputs_manager.clear_stack()
	
	var res_room = escoria.resource_cache.get_resource(command_params[0])
	
	# Load game scene
	if not escoria.game_scene:
		escoria.logger.report_errors(
			"ChangeSceneCommand.run: Failed loading game scene",
			[
				"Failed loading scene %s" % \
						ProjectSettings.get_setting("escoria/ui/game_scene")
			]
		)
	
	if escoria.main.current_scene \
			and escoria.game_scene.get_parent() == escoria.main.current_scene:
		escoria.main.current_scene.remove_child(escoria.game_scene)
	
	# Load room scene
	var room_scene = res_room.instance()
	if room_scene:
		if command_params[1] \
				and escoria.event_manager.get_running_event("_front").name \
				== "room_selector":
			room_scene.enabled_automatic_transitions = true
		else:
			room_scene.enabled_automatic_transitions = command_params[1]
		room_scene.exited_previous_room = exited_previous_room
		
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
		
		# Clear queued resources
		escoria.resource_cache.clear()
		
		escoria.inputs_manager.hotspot_focused = ""
	else:
		escoria.logger.report_errors(
			"ChangeSceneCommand.run: Failed loading room scene", 
			[
				"Failed loading scene %s" % command_params[0]
			]
		)
		return ESCExecution.RC_ERROR
	
	return ESCExecution.RC_OK
