# Background music player
extends Control
class_name ESCMusicPlayer


# Global id of the background music player
export var global_id: String = "_music"


# The state of the music player. "default" or "off" disable music
# Any other state refers to a music stream that should be played
var state: String = "default"


# Reference to the audio player
onready var stream: AudioStreamPlayer = $AudioStreamPlayer


# Set the state of this player
#
# #### Parameters
#
# - p_state: New state to use
# - p_force: Override the existing state even if the stream is still playing
func set_state(p_state: String, p_force: bool = false) -> void:
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
		resource.set_loop(true)
		if ProjectSettings.has_setting("escoria/sound/music_volume"):
			stream.volume_db = ProjectSettings.get_setting("escoria/sound/music_volume")
		stream.play()


# Register to the object registry
func _ready():
	escoria.object_manager.register_object(
		ESCObject.new(global_id, self),
		true
	)

