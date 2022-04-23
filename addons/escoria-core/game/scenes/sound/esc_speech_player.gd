# Speech player
extends Control
class_name ESCSpeechPlayer


# Global id of the background music player
export var global_id: String = "_speech"


# Set the state of this player
#
# #### Parameters
#
# - p_state: New state to use
# - p_force: Override the existing state even if the stream is still playing
func set_state(p_state: String, p_force: bool = false) -> void:
	# If speech is disabled, return
	if not escoria.settings.speech_enabled:
		return

	# If state is "off"/"default", turn off speech
	if p_state in ["off", "default"]:
		$AudioStreamPlayer.stream = null
		return

	var resource = load(p_state)

	$AudioStreamPlayer.stream = resource

	if $AudioStreamPlayer.stream:
		resource.set_loop(false)
		$AudioStreamPlayer.play()


# Register to the object registry
func _ready():
	pause_mode = Node.PAUSE_MODE_STOP
	escoria.object_manager.register_object(
		ESCObject.new(global_id, self),
		null,
		true
	)


func _on_AudioStreamPlayer_finished() -> void:
	set_state("off")
