extends Control
class_name ESCBackgroundMusic

func get_class():
	return "ESCBackgroundMusic"

onready var stream = $AudioStreamPlayer
var state = "default"
export var global_id = "bg_music"


func game_cleared():
	set_state("off", true)
	escoria.object_manager.register_object(
		ESCObject.new(global_id, self), 
		true
	)


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
		resource.set_loop(true)
		if ProjectSettings.has_setting("escoria/sound/music_volume"):
			stream.volume_db = ProjectSettings.get_setting("escoria/sound/music_volume")
		stream.play()

func _ready():
	escoria.object_manager.register_object(
		ESCObject.new(global_id, self),
		true
	)

