tool
extends Area2D
class_name ESCTriggerZone

func get_class():
	return "ESCTriggerZone"


export(String) var global_id
export(String, FILE, "*.esc") var esc_script

func _ready():
	assert(!global_id.empty())
	escoria.register_object(self)
	connect("area_entered", self, "element_entered")
	connect("area_exited", self, "element_exited")
	connect("body_entered", self, "element_entered")
	connect("body_exited", self, "element_exited")
	

func element_entered(body):
	if body is ESCBackground or body.get_parent() is ESCBackground:
		return
	escoria.do("trigger_in", [global_id, body.global_id])


func element_exited(body):
	escoria.do("trigger_out", [global_id, body.global_id])



