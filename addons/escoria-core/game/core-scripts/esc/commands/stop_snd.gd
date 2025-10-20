## `stop_snd([audio_bus: String])`
##
## Stops the given audio bus's stream.[br]
##[br]
## By default there are 3 audio buses set up by Escoria : `_sound`, which is
## used to play non-looping sound effects; `_music`, which plays looping music;
## and `_speech`, which plays non-looping voice files (default: `_music`).[br]
##[br]
## Each simultaneous sound (e.g. multiple game sound effects) will require its
## own bus. To create additional buses, see the Godot sound documentation :
## [Audio buses](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html#doc-audio-buses)[br]
##[br]
## **Parameters**[br]
##[br]
## - *audio_bus*: Bus to stop ("_sound", "_music", "_speech", or a custom
##   audio bus you have created.)
##
## @ESC
extends ESCBaseCommand
class_name StopSndCommand


## The specified sound player
var _snd_player: String

## The previous sound state, saved for interrupting
var previous_snd_state: String


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		0,
		[TYPE_STRING],
		["_music"]
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

	if not escoria.object_manager.has(arguments[0]):
		raise_error(
			self,
			"Invalid sound player. Sound player '%s' not registered." % arguments[0]
		)
		return false
	_snd_player = arguments[0]
	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	var sound_player = escoria.object_manager.get_object(command_params[0]).node
	if sound_player:
		if sound_player.get("state"):
			previous_snd_state = sound_player.state
		sound_player.set_state("off")
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	var _sound_players = []
	if previous_snd_state.is_empty():
		previous_snd_state = "off"

	if _snd_player.is_empty():
		_sound_players = [
			ESCObjectManager.MUSIC,
			ESCObjectManager.SOUND,
			ESCObjectManager.SPEECH
		]
	else:
		_sound_players = [_snd_player]

	for snd_player in _sound_players:
		if escoria.object_manager.get_object(snd_player).node:
			escoria.object_manager.get_object(snd_player).node.set_state(
				previous_snd_state
			)
