# Speech player
extends Control
class_name ESCSpeechPlayer


# Global id of the background music player
export var global_id: String = "_speech"

# Reference to the audio player
onready var stream: AudioStreamPlayer = $AudioStreamPlayer


# Set the state of this player
#
# #### Parameters
#
# - p_state: New state to use
# - from_seconds: Sets the starting playback position 
# - p_force: Override the existing state even if the stream is still playing
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


# Register to the object registry
func _ready():
	pause_mode = Node.PAUSE_MODE_STOP
	escoria.object_manager.register_object(
		ESCObject.new(global_id, self),
		null,
		true
	)


# Callback called when the audio stream player finished playing.
func _on_AudioStreamPlayer_finished() -> void:
	set_state("off")


# Pause the speech player
func pause():
	stream.stream_paused = true


# Unpause the speech player
func resume():
	stream.stream_paused = false


# Returns the playback position of the audio stream in seconds
#
# **Returns** playback position
func get_playback_position() -> float:
	return $AudioStreamPlayer.get_playback_position()
