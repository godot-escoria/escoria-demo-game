# `play_snd object file [loop]`
# 
# Plays the sound specificed with the "file" parameter on the object, without 
# blocking. You can play background sounds, eg. during scene changes, with 
# `play_snd bg_snd res://...`
#
# @STUB
# @ESC
extends ESCBaseCommand
class_name PlaySndCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING, TYPE_BOOL],
		[null, null, false]
	)


# Run the command
func run(command_params: Array) -> int:
	escoria.logger.report_errors(
		"play_snd: command not implemented",
		[]
	)
	return ESCExecution.RC_ERROR
