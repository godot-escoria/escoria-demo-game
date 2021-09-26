# `transition transition_name in|out [delay]`
#
# Performs a transition in our out manually.
# 
# Parameters:
# - transition_name: Name of the transition shader from one of the transition
#   directories
# - in|out: Wether to play the transition in IN- or OUT-mode
# - delay: Delay for the transition to take. Defaults to 1 second
# 
# @ESC
extends ESCBaseCommand
class_name TransitionCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING, TYPE_REAL],
		[null, null, 1.0]
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
	escoria.main.scene_transition.transition(
		command_params[0],
		ESCTransitionPlayer.TRANSITION_MODE.OUT if command_params[1] == "out" \
				else ESCTransitionPlayer.TRANSITION_MODE.IN,
		command_params[2]
	)
	yield(
		escoria.main.scene_transition, 
		"transition_done"
	)
	return ESCExecution.RC_OK
