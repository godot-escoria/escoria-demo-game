## Background music player
extends Control
class_name ESCMusicPlayer

## Global id of the background music player.
@export var global_id: String = "_music"

## The state of the music player. "default" or "off" disable music. Any other
## state refers to a music stream that should be played.
var state: String = "default"

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
	# If already playing this stream, keep playing, unless p_force
	if p_state == state and not p_force and stream.is_playing():
		return

	state = p_state

	# If state is "off"/"default", turn off music
	if state == "off" or state == "default":
		stream.stream = null
		return

	var resource = load(p_state)

	stream.stream = resource

	if stream.stream:
		if resource is AudioStreamWAV:
			resource.loop_mode = AudioStreamWAV.LOOP_FORWARD
			resource.loop_end = resource.mix_rate * resource.get_length()
		elif "loop" in resource:
			resource.loop = true
		stream.play(from_seconds)


## Registers this music player to the object registry.[br]
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


## The playback position of the audio stream in seconds.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the playback position of the audio stream in seconds. the playback position as a float value. (`float`)
func get_playback_position() -> float:
	return $AudioStreamPlayer.get_playback_position()
