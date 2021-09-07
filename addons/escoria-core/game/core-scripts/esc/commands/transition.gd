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
	if not escoria.main.scene_transition.has_transition(arguments[0]):
		escoria.logger.report_errors(
			"transition: argument invalid",
			[
				"transition with name '%s' doesn't exist" % arguments[0]
			]
		)
		return false
	if not arguments[1] in ["in", "out"]:
		escoria.logger.report_errors(
			"transition: argument invalid",
			[
				"'in' or 'out' expected, but got '%s'" % arguments[1]
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
