# `change_scene path [disable_automatic_transition] [run_events]`
#
# Loads a new scene, specified by "path". 
# The `disable_automatic_transition` is a boolean (default false) can be set 
# to true to disable automatic transitions between scenes, to allow you
# to control your transitions manually using the `transition` command.
# The `run_events` variable is a boolean (default true) which you never want 
# to set manually! It's there only to benefit save games, so they don't
# conflict with the scene's events.
#
# @ESC
extends ESCBaseCommand
class_name ChangeSceneCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_STRING, TYPE_BOOL, TYPE_BOOL],
		[null, false, true]
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
		"Changing scene to %s (disable_automatic_transition = %s, run_events = %s)" % [
		command_params[0],
		command_params[1],
		command_params[2]
	])
	
	if escoria.main.current_scene \
		and not escoria.globals_manager.get_global("BYPASS_LAST_SCENE"):
		escoria.globals_manager.set_global(
			"ESC_LAST_SCENE", 
			escoria.main.current_scene.global_id, 
			true
		)
		
	escoria.event_manager.interrupt_running_event()
	
	if !command_params[1]:
		escoria.main.scene_transition.transition(
			"", 
			ESCTransitionPlayer.TRANSITION_MODE.OUT
		)
		yield(escoria.main.scene_transition, "transition_done")
	
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
		room_scene.add_child(escoria.game_scene)
		room_scene.move_child(escoria.game_scene, 0)
		room_scene.game = escoria.game_scene
		escoria.main.set_scene(room_scene)
		
		# If automatic transition is not disabled, play the transition
		if not command_params[1]:
			escoria.main.scene_transition.transition()
			yield(escoria.main.scene_transition, "transition_done")
				
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
	
	# If the ESC_LAST_SCENE global was bypassed, reset bypass variable to false
	if escoria.globals_manager.get_global("BYPASS_LAST_SCENE"):
		escoria.globals_manager.set_global(
			"BYPASS_LAST_SCENE", 
			false, 
			true
		)

	return ESCExecution.RC_OK
