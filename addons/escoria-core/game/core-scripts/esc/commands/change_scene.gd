# `change_scene path run_events`
#
# Loads a new scene, specified by "path". The `run_events` variable is a 
# boolean (default true) which you never want to set manually! It's there only 
# to benefit save games, so they don't conflict with the scene's events.
#
# @ESC
extends ESCBaseCommand
class_name ChangeSceneCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_STRING, TYPE_BOOL],
		[null, true]
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
	escoria.logger.info("Changing scene to %s (run_events = %s)" % [
		command_params[0], 
		command_params[1]
	])
	
	if escoria.main.current_scene:
		escoria.globals_manager.set_global(
			"ESC_LAST_SCENE", 
			escoria.main.current_scene.global_id, 
			true
		)
		
	escoria.main.scene_transition.fade_out()
	yield(escoria.main.scene_transition, "transition_done")
	
	escoria.main_menu_instance.hide()
	
	var res_room = escoria.resource_cache.get_resource(command_params[0])
	var res_game = escoria.resource_cache.get_resource(
		ProjectSettings.get_setting("escoria/ui/game_scene")
	)
		
	# Load game scene
	var game_scene = res_game.instance()
	if not game_scene:
		escoria.logger.report_errors(
			"ChangeSceneCommand.run: Failed loading game scene",
			[
				"Failed loading scene %s" % \
						ProjectSettings.get_setting("escoria/ui/game_scene")
			]
		)
	
	# Load room scene
	var room_scene = res_room.instance()
	if room_scene:
		room_scene.add_child(game_scene)
		room_scene.move_child(game_scene, 0)
		escoria.main.set_scene(room_scene)
		
		if "esc_script" in room_scene and room_scene.esc_script \
				and command_params[1]:
			
			var script = escoria.esc_compiler.load_esc_file(
				room_scene.esc_script
			)
			
			if script.events.has("setup"):
				escoria.event_manager.queue_event(script.events["setup"])
				var rc = yield(escoria.event_manager, "event_finished")
				while rc[1] != "setup":
					rc = yield(escoria.event_manager, "event_finished")
				if rc[0] != ESCExecution.RC_OK:
					return rc[0]
			
			escoria.main.scene_transition.fade_in()
			yield(escoria.main.scene_transition, "transition_done")
		
			if script.events.has("ready"):
				escoria.event_manager.queue_event(script.events["ready"])
				var rc = yield(escoria.event_manager, "event_finished")
				while rc[1] != "ready":
					rc = yield(escoria.event_manager, "event_finished")
				if rc[0] != ESCExecution.RC_OK:
					return rc[0]
				
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
