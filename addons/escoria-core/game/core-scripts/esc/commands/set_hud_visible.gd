# `set_hud_visible visible`
#
# If you have a cutscene like sequence where the player doesn't have control, 
# and you also have HUD elements visible, use this to hide the HUD. You want 
# to do that because it explicitly signals the player that there is no control 
# over the game at the moment. "visible" is true or false.
#
# @ESC
extends ESCBaseCommand
class_name SetHudVisibleCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_BOOL],
		[null]
	)


# Run the command
func run(command_params: Array) -> int:
	if command_params[0]:
		escoria.main.current_scene.game.show_ui()
	else:
		escoria.main.current_scene.game.hide_ui()
	return ESCExecution.RC_OK
