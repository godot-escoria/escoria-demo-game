## `transition transition_name mode [delay]`
##
## Runs a transition effect - generally used when entering or leaving a room.
## Transitions are implemented as Godot shaders. Custom transitions can be made
## by creating a shader in the `game/scenes/transitions/shaders/` folder within
## the escoria-core plugin folder.[br]
##[br]
## **Parameters**[br]
##[br]
## - *transition_name*: Name of the transition shader from one of the transition
##   directories[br]
## - *mode*: Set to `in` to transition into or `out` to transition out of the room[br]
## - *delay*: Delay in seconds before starting the transition (default: `1.0`)
##
## @ESC
extends ESCBaseCommand
class_name TransitionCommand


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_FLOAT],
		[null, null, 1.0]
	)


## Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.main.scene_transition.has_transition(arguments[0]) \
		and not arguments[0].is_empty():
		raise_error(
			self,
			"Argument invalid. Transition with name '%s' doesn't exist." % arguments[0]
		)
		return false
	if not arguments[1] in ["in", "out"]:
		raise_error(
			self,
			"Argument invalid. Transition type 'in' or 'out' expected, but '%s' was provided." % arguments[1]
		)
		return false
	return true


## Run the command
func run(command_params: Array) -> int:
	var transition_id = escoria.main.scene_transition.transition(
		command_params[0],
		ESCTransitionPlayer.TRANSITION_MODE.OUT if command_params[1] == "out" \
				else ESCTransitionPlayer.TRANSITION_MODE.IN,
		command_params[2]
	)

	if transition_id == ESCTransitionPlayer.TRANSITION_ID_INSTANT:
		escoria.logger.debug(
			self,
			"Performing instant transition."
		)
		escoria.main.scene_transition.reset_shader_cutoff()
		return ESCExecution.RC_OK

	escoria.logger.debug(
		self,
		"Starting transition #%s [%s, %s]."
				% [transition_id, command_params[0], command_params[1]]
	)
	while await escoria.main.scene_transition.transition_done != transition_id:
		pass
	escoria.logger.debug(
		self,
		"Ending transition #%s [%s, %s]."
				% [transition_id, command_params[0], command_params[1]])
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
