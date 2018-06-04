extends Position2D

export(String) var global_id

func get_interact_pos():
	return get_global_position()

func _ready():
	vm.register_object(global_id, self)

