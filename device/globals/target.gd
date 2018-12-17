extends Position2D

export(String) var global_id

var audio
var camera_pos

func get_interact_pos():
	return get_global_position()

func get_camera_pos():
	if camera_pos:
		return camera_pos.get_global_position()

	return get_global_position()

func play_snd(p_snd, p_loop=false):
	if !audio:
		vm.report_errors("item", ["play_snd called with no audio node"])
		return

	var resource = load(p_snd)
	if !resource:
		vm.report_errors("item", ["play_snd resource not found " + p_snd])
		return

	audio.stream = resource
	audio.stream.set_loop(p_loop)
	audio.play()

func _ready():
	if has_node("camera_pos"):
		camera_pos = $"camera_pos"

	if has_node("audio"):
		audio = $"audio"
		audio.set_bus("SFX")

	vm.register_object(global_id, self)

