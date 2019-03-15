extends NavigationPolygonInstance

export(String) var global_id

func set_active(p_active):
	enabled = p_active

	if enabled:
		show()
	else:
		hide()

func _ready():
	vm.register_object(global_id, self)

