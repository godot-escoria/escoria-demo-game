extends Node

var light = null
var caster = null
var polygon = null

var in_caster
var light_floor_pos
var vector_to
var alpha
var alpha_calculated

onready var space = get_world_2d().get_direct_space_state()
onready var perspective_scale = $"perspective_scale"
onready var rotation = perspective_scale.get_node("rotation")
onready var shadow = rotation.get_node("shadow")

export var rotating = true
export var scaling = true

func start(p_caster, p_polygon):
	caster = p_caster
	polygon = p_polygon

	light = p_caster.get_parent()

	self.visible = true

	set_process(true)

func stop():
	self.queue_free()

func shadow_in_caster():
	for shape in space.intersect_point(self.global_position):
		if shape["collider"] == caster:
			return true

	return false

func _process(delta):
	in_caster = shadow_in_caster()
	if not in_caster:
		self.visible = false
		return
	elif in_caster and not self.visible:
		self.visible = true

	light_floor_pos = light.global_position + Vector2(0, caster.light_y_offset)
	vector_to = shadow.global_position - light_floor_pos

	# Recalculate shadow's alpha.
	# The closer the light source, the bigger the alpha value
	alpha = (caster.max_dist_visible / vector_to.length()) * caster.alpha_coefficient
	# TODO: Should have some code to grade off the shadow when close to the polygon's edge
	alpha_calculated = clamp(alpha, 0.0, caster.alpha_max)
	# printt("ALPHA", alpha_calculated)
	shadow.get_material().set_shader_param("alpha_value", alpha_calculated)
	if alpha_calculated < 0.1:
		shadow.get_material().set_shader_param("alpha_value", 0.0)
		return

	# Rotate the shadow so it faces the light
	if rotating:
		rotation.look_at(shadow.global_position - vector_to)
		rotation.rotate(PI)

	# Scale the shadow according to its distance to light source
	# The closer the light, the shorter its height (down to the minimum size)
	if scaling:
		shadow.scale.x = pow(vector_to.length(), caster.scale_power) / caster.scale_divide + caster.scale_extra

func _ready():
	# We are always the "template" for shadows, so we ourselves can't be visible
	self.visible = false

	set_process(false)

