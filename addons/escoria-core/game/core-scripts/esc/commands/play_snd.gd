# `play_snd file [player]`
#
# Plays the specified sound without blocking the currently running event.
#
# **Parameters**
#
# - *file*: Sound file to play
# - *player*: Sound player to use. Can either be `_sound`, which is used to play non-
#   looping sound effects; `_music`, which plays looping music; or `_speech`, which
#   plays non-looping voice files (default: `_sound`)
#
# @ESC
extends ESCBaseCommand
class_name PlaySndCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING],
		[null, "_sound"]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.has(arguments[1]):
		escoria.logger.report_errors(
			"play_snd: invalid sound player",
			["Sound player %s not registered" % arguments[1]]
		)
		return false
	if not ResourceLoader.exists(arguments[0]):
		escoria.logger.report_errors(
			"play_snd: invalid parameter",
			["File %s not found" % arguments[0]]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.object_manager.get_object(command_params[1]).node.set_state(
		command_params[0]
	)
	return ESCExecution.RC_OK
