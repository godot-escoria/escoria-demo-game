# `stop_snd [player]`
#
# Stops the given sound player's stream.
#
# **Parameters**
#
# - *player*: Sound player to use. Either `_sound`, which is used to play non-
#   looping sound effects; `_music`, which plays looping music; or `_speech`, which
#   plays non-looping voice files (default: `_music`)
#
# @ESC
extends ESCBaseCommand
class_name StopSndCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		0,
		[TYPE_STRING],
		["_music"]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.report_errors(
			"stop_snd: invalid sound player",
			["Sound player %s not registered" % arguments[1]]
		)
		return false
	return true


# Run the command
func run(command_params: Array) -> int:
	escoria.object_manager.get_object(command_params[0]).node.set_state(
		"off"
	)
	return ESCExecution.RC_OK
