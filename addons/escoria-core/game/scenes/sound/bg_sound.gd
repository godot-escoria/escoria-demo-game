extends Control
class_name ESCBackgroundSound

func get_class():
	return "ESCBackgroundSound"

onready var stream = $AudioStreamPlayer
var state = "default"
export var global_id = "bg_sound"


func game_cleared():
	stream.stream = null
	escoria.register_object(self)


func set_state(p_state, p_force = false):
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
		resource.set_loop(false)
		if ProjectSettings.has_setting("escoria/sound/sound_volume"):
			stream.volume_db = ProjectSettings.get_setting("escoria/sound/sound_volume")
		stream.play()


func _ready():
	escoria.register_object(self)
