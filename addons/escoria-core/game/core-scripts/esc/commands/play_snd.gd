## `play_snd file [player] [start_position_seconds]`[br]
## [br]
## Plays the specified sound without blocking the currently running event.[br]
## [br]
## #### Parameters[br]
## [br]
## - *file*: Sound file to play[br]
## - *player*: Sound player to use. Can either be `_sound`, which is used to play non-
##   looping sound effects; `_music`, which plays looping music; or `_speech`, which
##   plays non-looping voice files (default: `_sound`)[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name PlaySndCommand


## The specified sound player
var _snd_player: String


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING, TYPE_STRING, TYPE_FLOAT],
		[null, "_sound", 0.0]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## - arguments: The arguments to validate.[br]
## [br]
## *Returns* True if the arguments are valid, false otherwise.
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


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	escoria.object_manager.get_object(command_params[1]).node.set_state(
		command_params[0], command_params[2]
	)
	return ESCExecution.RC_OK
