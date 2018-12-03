extends Control

var stream

var state = "default"

export var global_id = "bg_snd"

func game_cleared():
	stream.stream = null
	self.disconnect("tree_exited", vm, "object_exit_scene")
	vm.register_object(global_id, self)

func play_snd(p_snd, p_loop=false):
	var resource = load(p_snd)
	if !resource:
		vm.report_errors("bg_snd", ["play_snd resource not found " + p_snd])
		return
	stream.stream = resource
	stream.stream.set_loop(p_loop)
	stream.volume_db = vm.settings.sfx_volume
	stream.play()

func _ready():
	stream = $"stream"

	vm.register_object(global_id, self)

	add_to_group("game")

