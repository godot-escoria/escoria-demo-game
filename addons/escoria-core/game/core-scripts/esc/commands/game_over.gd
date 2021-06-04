# `game_over continue_enabled show_credits`
#
# Ends the game. Use the "continue_enabled" parameter to enable or disable the 
# continue button in the main menu afterwards. The "show_credits" parameter 
# loads the ui/end_credits scene if true. You can configure it to your regular 
# credits scene if you want.
#
# @STUB
# @ESC
extends ESCBaseCommand
class_name GameOverCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		0, 
		[TYPE_BOOL, TYPE_BOOL],
		[false, true]
	)


# Run the command
func run(command_params: Array) -> int:
	escoria.logger.report_errors(
		"game_over: command not implemented",
		[]
	)
	return ESCExecution.RC_ERROR
