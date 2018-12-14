extends Position2D

export(String) var global_id

var camera_pos

func get_interact_pos():
	return get_global_position()

func get_camera_pos():
	if camera_pos:
		return camera_pos.get_global_position()

	return get_global_position()

func _ready():
	if has_node("camera_pos"):
		camera_pos = $"camera_pos"

	vm.register_object(global_id, self)

