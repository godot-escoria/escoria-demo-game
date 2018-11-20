extends Control

var stream

var state = "default"

export var global_id = "bg_music"

func game_cleared():
	set_state("off", true)
	self.disconnect("tree_exited", vm, "object_exit_scene")
	vm.register_object(global_id, self)

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
		stream.play()
		stream.volume_db = vm.settings.music_volume

func _ready():
	stream = $"stream"

	vm.register_object(global_id, self)

	add_to_group("game")

