# `show_menu menu_type [enable_automatic_transition]`
#
# Shows either the main menu or the pause menu.
#
# **Parameters**
#
# - *menu_type*: Type of menu to hide. Can be either `main` or `pause` (default: `main`)
# - *enable_automatic_transition*: Whether to automatically transition to the menu (default: `false`)
#
# @ESC
extends ESCBaseCommand
class_name ShowMenuCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		0,
		[TYPE_STRING, TYPE_BOOL],
		["main", false]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not arguments[0] in ["main", "pause"]:
		escoria.logger.report_errors(
			"show_menu: invalid menu ",
			[
				"menu %s is invalid" % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	if not escoria.game_scene.is_inside_tree():
		escoria.add_child(escoria.game_scene)

	if command_params[1]:
		# Transition out from current scene
		var transition_id = escoria.main.scene_transition.transition(
			"",
			ESCTransitionPlayer.TRANSITION_MODE.OUT
		)
		while yield(
			escoria.main.scene_transition,
			"transition_done"
		) != transition_id:
			pass

		if command_params[0] == "main":
			escoria.game_scene.show_main_menu()
		elif command_params[0] == "pause":
			escoria.game_scene.pause_game()

		# Transition in to menu
		transition_id = escoria.main.scene_transition.transition()

		while yield(
			escoria.main.scene_transition,
			"transition_done"
		) != transition_id:
			pass

	else:
		if command_params[0] == "main":
			escoria.game_scene.show_main_menu()
		elif command_params[0] == "pause":
			escoria.game_scene.pause_game()

	return ESCExecution.RC_OK
