extends Area2D

var light
var shadow
var polygon

export (int)var light_y_offset = 0
export (float)var max_dist_visible = 50
export (float)var alpha_coefficient = 2.0
export (float)var alpha_max = 0.65
export (float)var scale_power = 1.2
export (float)var scale_divide = 1000.0
export (float)var scale_extra = 0.15

func body_entered(body):
	if not light.visible:
		return

	printt(body.name, " entered ", get_parent().name)

	if body.has_node("shadow"):
		shadow = body.get_node("shadow").duplicate()
		body.add_child(shadow)
		shadow.start(self, polygon)

func body_exited(body):
	if not light.visible:
		return

	if not shadow:
		vm.report_errors("shadow_caster", [body.name + " leaving " + get_parent().name + " with no shadow"])

	printt(body.name, " exited  ", get_parent().name)

	shadow.stop()

func _ready():
	light = get_parent()

	if not light is Light2D:
		vm.report_errors("shadow_caster", ["parent is not Light2D"])

	for child in get_children():
		if child is CollisionPolygon2D:
			polygon = child
			break

	connect("body_entered", self, "body_entered")
	connect("body_exited", self, "body_exited")

