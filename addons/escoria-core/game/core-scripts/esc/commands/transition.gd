# `transition transition_name mode [delay]`
#
# Runs a transition effect - generally used when entering or leaving a room.
# Transitions are implemented as Godot shaders. Custom transitions can be made
# by creating a shader in the `game/scenes/transitions/shaders/` folder within
# the escoria-core plugin folder.
#
# **Parameters**
#
# - *transition_name*: Name of the transition shader from one of the transition
#   directories
# - *mode*: Set to `in` to transition into or `out` to transition out of the room
# - *delay*: Delay in seconds before starting the transition (default: `1.0`)
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


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.main.scene_transition.has_transition(arguments[0]) \
		and not arguments[0].empty():
		escoria.logger.error(
			self,
			"[%s]: argument invalid. Transition with name '%s' doesn't exist."
					% [get_command_name(), arguments[0]]
		)
		return false
	if not arguments[1] in ["in", "out"]:
		escoria.logger.error(
			self,
			"[%s]: argument invalid" +
				"Transition type 'in' or 'out' expected, but '%s' was provided."
					% [get_command_name(), arguments[1]]
		)
		return false
	return true


# Run the command
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
	while yield(
		escoria.main.scene_transition,
		"transition_done"
	) != transition_id:
		pass
	escoria.logger.debug(
		self,
		"Ending transition #%s [%s, %s]."
				% [transition_id, command_params[0], command_params[1]])
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
