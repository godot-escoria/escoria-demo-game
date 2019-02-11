extends Sprite

const MAX_DIST_VISIBLE = 50.0
const LIGHT_HEIGHT = 180.0

var light = null

export var rotating = true
export var scaling = true
export var scale_by_node = "sprite"

func _ready():
	for node in get_parent().get_parent().get_parent().get_parent().get_children():
		if node is Light2D and node.visible:
			light = node
			break

func _process(delta):
	var light_floor_pos = light.global_position + Vector2(0,LIGHT_HEIGHT)
	var vector_to = global_position - light_floor_pos
	var direction = vector_to.normalized()

	# Recalculate shadow's alpha.
	# The closer the light source, the bigger the alpha value
	var alpha_calculated = clamp((MAX_DIST_VISIBLE/vector_to.length()) * 2.0, 0.0, 0.65)
	# printt("ALPHA", alpha_calculated)
	get_material().set_shader_param("alpha_value", alpha_calculated)
	if alpha_calculated < 0.1:
		get_material().set_shader_param("alpha_value", 0.0)
		return

	# Rotate the shadow so it faces the light
	if rotating:
		get_parent().look_at(global_position - vector_to)
		get_parent().rotate(PI)

	# Scale the shadow according to its distance to light source
	# The closer the light, the shorter its height (down to the minimum size)
	if scaling:
		# printt("direction", direction)
		scale.x = pow(vector_to.length(),1.2)/1000.0 + 0.15

