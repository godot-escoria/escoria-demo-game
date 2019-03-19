extends Area2D

export var global_id = ""
export var active = true setget set_active,get_active

func set_active(p_active):
	active = p_active
	if p_active:
		show()
	else:
		hide()

func get_active():
	return active

func body_entered(body):
	if "check_maps" in body:
		body.check_maps = true

func body_exited(body):
	if "check_maps" in body:
		body.check_maps = false

func _ready():
	connect("body_entered", self, "body_entered")
	connect("body_exited", self, "body_exited")

	vm.register_object(global_id, self)

