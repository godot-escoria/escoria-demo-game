## `hide_menu(menu_type: String)`
##
## Hides either the main menu or the pause menu. Transitions from the menu using
## the default transition type (set in the Escoria project settings).[br]
##[br]
## **Parameters**[br]
##[br]
## - *menu_type*: Which menu to hide. Can be either `main` or `pause` (default: `main`)
##
## @ESC
extends ESCBaseCommand
class_name HideMenuCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		0,
		[TYPE_STRING],
		["main"]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## - arguments: The arguments to validate.[br]
## [br]
## *Returns* True if the arguments are valid, false otherwise.
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not arguments[0] in ["main", "pause"]:
		raise_error(self, "Menu %s is invalid." % arguments[0])
		return false
	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	var transition_id: int

	# Transition out from menu
	transition_id = escoria.main.scene_transition.transition(
		"",
		ESCTransitionPlayer.TRANSITION_MODE.OUT
	)

	if transition_id != ESCTransitionPlayer.TRANSITION_ID_INSTANT:
		while await escoria.main.scene_transition.transition_done != transition_id:
			pass

	if command_params[0] == "main":
		escoria.game_scene.hide_main_menu()
	elif command_params[0] == "pause":
		escoria.game_scene.unpause_game()

	if escoria.main.current_scene != null:
		transition_id = escoria.main.scene_transition.transition()

		if transition_id != ESCTransitionPlayer.TRANSITION_ID_INSTANT:
			while await escoria.main.scene_transition.transition_done != transition_id:
				pass

	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
