# `transition transition_name in|out`
#
# Performs a fade in or fade out transition manually.
# 
# @ESC
extends ESCBaseCommand
class_name FadeCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING],
		[null, null]
	)
	
	
# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not arguments[0] in ["in", "out"]:
		escoria.logger.report_errors(
			"fade: argument invalid",
			[
				"'in' or 'out' expected, but got '%s'" % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	var transition_player = escoria.main.scene_transition
	transition_player.call("transition_%s" % command_params[1], command_params[0])
	var animation_finished = yield(transition_player, "transition_done")
	return ESCExecution.RC_OK
