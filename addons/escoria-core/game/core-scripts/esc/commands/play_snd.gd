## `play_snd(file: String[, player: String[, start_position_seconds: Number]])`
##
## Plays the specified sound without blocking the currently running event.[br]
##[br]
## **Parameters**[br]
##[br]
## - *file*: Sound file to play[br]
## - *player*: Sound player to use. Can either be `_sound`, which is used to play non-
##   looping sound effects; `_music`, which plays looping music; or `_speech`, which
##   plays non-looping voice files (default: `_sound`)
##
## @ESC
extends ESCBaseCommand
class_name PlaySndCommand


## The specified sound player
var _snd_player: String


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING, TYPE_STRING, TYPE_FLOAT],
		[null, "_sound", 0.0]
	)


## Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[1]):
		raise_error(self, "Invalid sound player. Sound player %s not registered." % arguments[1])
		return false
	if not ResourceLoader.exists(arguments[0]):
		raise_error(self, "Invalid argument. File '%s' not found." % arguments[0])
		return false
	_snd_player = arguments[1]
	return true


## Run the command
func run(command_params: Array) -> int:
	escoria.object_manager.get_object(command_params[1]).node.set_state(
		command_params[0], command_params[2]
	)
	return ESCExecution.RC_OK
