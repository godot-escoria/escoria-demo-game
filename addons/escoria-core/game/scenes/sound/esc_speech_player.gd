## Speech player
extends Control
class_name ESCSpeechPlayer

## Global id of the background music player.
@export var global_id: String = "_speech"

## Reference to the audio player.
@onready var stream: AudioStreamPlayer = $AudioStreamPlayer

## Sets the state of this player.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_state|`String`|New state to use.|yes|[br]
## |from_seconds|`float`|Sets the starting playback position.|no|[br]
## |p_force|`bool`|Override the existing state even if the stream is still playing.|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_state(p_state: String, from_seconds: float = 0.0, p_force: bool = false) -> void:
	# If speech is disabled, return
	if not ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.SPEECH_ENABLED
	):
		return

	# If state is "off"/"default", turn off speech
	if p_state in ["off", "default"]:
		stream.stream = null
		return

	var resource = load(p_state)
	stream.stream = resource

	if stream.stream:
		stream.stream.set_loop(false)
		$AudioStreamPlayer.play(from_seconds)


## Registers this speech player to the object registry.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	escoria.object_manager.register_object(
		ESCObject.new(global_id, self),
		null,
		true
	)


## Callback called when the audio stream player finished playing.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _on_AudioStreamPlayer_finished() -> void:
	set_state("off")


## Pauses the speech player.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func pause():
	stream.stream_paused = true


## Unpauses the speech player.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func resume():
	stream.stream_paused = false


## The playback position of the audio stream in seconds.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the playback position of the audio stream in seconds. The playback position in seconds. (`float`)
func get_playback_position() -> float:
	return $AudioStreamPlayer.get_playback_position()
