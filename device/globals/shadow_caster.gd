extends Area2D

var light
var shadows = {}
var polygon

var bkp_mask

export (bool)var force_light_mask = true

## These are used in shadow.gd
#warning-ignore:unused_class_variable
export (int)var light_y_offset = 0
#warning-ignore:unused_class_variable
export (float)var max_dist_visible = 50
#warning-ignore:unused_class_variable
export (float)var alpha_coefficient = 2.0
#warning-ignore:unused_class_variable
export (float)var alpha_max = 0.65
#warning-ignore:unused_class_variable
export (float)var scale_power = 1.2
#warning-ignore:unused_class_variable
export (float)var scale_divide = 1000.0
#warning-ignore:unused_class_variable
export (float)var scale_extra = 0.15

func change_light_mask(body, cull_mask):
	body.light_mask = cull_mask
	for child in body.get_children():
		if "light_mask" in child:
			change_light_mask(child, cull_mask)

func get_id(body):
	var body_id

	if not "global_id" in body:
		assert body is esc_type.PLAYER
		body_id = "player"
	else:
		body_id = body.global_id

	return body_id

func body_entered(body):
	if not light.visible:
		return

	if not self.visible:
		return

	printt(body.name, " entered ", get_parent().name)

	if force_light_mask and body.light_mask != light.range_item_cull_mask:
		bkp_mask = body.light_mask
		change_light_mask(body, light.range_item_cull_mask)

	if body.has_node("shadow"):
		var body_id = get_id(body)

		shadows[body_id] = body.get_node("shadow").duplicate()
		body.add_child(shadows[body_id])
		shadows[body_id].start(self, polygon)

func body_exited(body):
	if not light.visible:
		return

	if not self.visible:
		return

	var body_id = get_id(body)

	if not body_id in shadows:
		vm.report_errors("shadow_caster", [body.name + " leaving " + get_parent().name + " with no shadow"])

	printt(body.name, " exited  ", get_parent().name)

	if force_light_mask and bkp_mask != null:
		change_light_mask(body, bkp_mask)
		bkp_mask = null

	shadows[body_id].stop()
	shadows.erase(body_id)

func _ready():
	var conn_err

	light = get_parent()

	if not light is Light2D:
		vm.report_errors("shadow_caster", ["parent is not Light2D"])

	for child in get_children():
		if child is CollisionPolygon2D:
			polygon = child
			break

	conn_err = connect("body_entered", self, "body_entered")
	if conn_err:
		vm.report_errors("shadow_caster", ["body_entered -> body_entered error: " + String(conn_err)])

	conn_err = connect("body_exited", self, "body_exited")
	if conn_err:
		vm.report_errors("item", ["body_exited -> body_exited error: " + String(conn_err)])


