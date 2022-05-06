# `hide_menu menu_type [enable_automatic_transition]`
#
# Hides either the main menu or the pause menu. The enable_automatic_transition
# parameter can be used to specify if Escoria manages the graphical transition
# for you or not.
# Setting `enable_automatic_transition` to false allows you to manage the
# transition effect for your room as it transitions in and out. Place a
# `transition` command in the room's `setup` event to manage the look of the
# transition in, and in the room's `exit_scene` event to manage the look of the
# transition out.
#
# **Parameters**
#
# - *menu_type*: Which menu to hide. Can be either `main` or `pause` (default: `main`)
# - *enable_automatic_transition*: Whether to automatically transition from the menu (default: `false`)
#
# @ESC
extends ESCBaseCommand
class_name HideMenuCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		0,
		[TYPE_STRING, TYPE_BOOL],
		["main", false]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not arguments[0] in ["main", "pause"]:
		escoria.logger.error(
			self,
			get_command_name() + ": menu %s is invalid" % arguments[0]
		)
		return false
	return true


# Run the command
func run(command_params: Array) -> int:
	var transition_id: int
	if command_params[1]:
		# Transition out from menu
		transition_id = escoria.main.scene_transition.transition(
			"",
			ESCTransitionPlayer.TRANSITION_MODE.OUT
		)

		if transition_id != ESCTransitionPlayer.TRANSITION_ID_INSTANT:
			while yield(
				escoria.main.scene_transition,
				"transition_done"
			) != transition_id:
				pass

	if command_params[0] == "main":
		escoria.game_scene.hide_main_menu()
	elif command_params[0] == "pause":
		escoria.game_scene.unpause_game()

	if command_params[1] and escoria.main.current_scene != null:
		transition_id = escoria.main.scene_transition.transition()

		if transition_id != ESCTransitionPlayer.TRANSITION_ID_INSTANT:
			while yield(
				escoria.main.scene_transition,
				"transition_done"
			) != transition_id:
				pass

	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
