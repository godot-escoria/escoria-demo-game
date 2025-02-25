## `show_menu menu_type`
##
## Shows either the main menu or the pause menu. Transitions to the menu using
## the default transition type (set in the Escoria project settings).[br]
##[br]
## **Parameters**[br]
##[br]
## - *menu_type*: Which menu to show. Can be either `main` or `pause` (default: `main`)
##
## @ESC
extends ESCBaseCommand
class_name ShowMenuCommand


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		0,
		[TYPE_STRING],
		["main"]
	)


## Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not arguments[0] in ["main", "pause"]:
		raise_error(
			self,
			"Menu '%s' is invalid." % arguments[0]
		)
		return false
	return true


## Run the command
func run(command_params: Array) -> int:
	if not escoria.game_scene.is_inside_tree():
		escoria.add_child(escoria.game_scene)

	# Transition out from current scene
	var transition_id = escoria.main.scene_transition.transition(
		"",
		ESCTransitionPlayer.TRANSITION_MODE.OUT
	)

	if transition_id != ESCTransitionPlayer.TRANSITION_ID_INSTANT:
		while await escoria.main.scene_transition.transition_done \
				!= transition_id:
			pass

	if command_params[0] == "main":
		escoria.game_scene.show_main_menu()
	elif command_params[0] == "pause":
		escoria.game_scene.pause_game()

	# Transition in to menu
	transition_id = escoria.main.scene_transition.transition()

	if transition_id != ESCTransitionPlayer.TRANSITION_ID_INSTANT:
		while await escoria.main.scene_transition.transition_done \
				!= transition_id:
			pass

	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
