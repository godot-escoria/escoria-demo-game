# `stop_snd [player]`
# 
# Stops the stream of the given sound player
#
# **Parameters**
#
# - *player*: Sound player to use. Either _sound, which is used to play non-
#   looping sound effects or _music, which plays looping music or _speech, which
#   plays non-looping voice files (_music)
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
	

# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.report_errors(
			"play_snd: invalid sound player",
			["Sound player %s not registered" % arguments[1]]
		)
		return false
	return .validate(arguments)
	

# Run the command
func run(command_params: Array) -> int:
	escoria.object_manager.get_object(command_params[1]).node.set_state(
		"off"
	)
	return ESCExecution.RC_OK
