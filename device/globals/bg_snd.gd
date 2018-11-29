extends Control

var stream

var state = "default"

export var global_id = "bg_snd"

func game_cleared():
	stream.stream = null
	self.disconnect("tree_exited", vm, "object_exit_scene")
	vm.register_object(global_id, self)

func play_snd(p_snd):
	var resource = load(p_snd)
	if !resource:
		return
	stream.stream = resource
	stream.stream.set_loop(false)
	stream.volume_db = vm.settings.sfx_volume
	stream.play()

func _ready():
	stream = $"stream"

	vm.register_object(global_id, self)

	add_to_group("game")

