extends Sprite

const MAX_DIST_VISIBLE = 50.0

var lights = []

export var rotating = true
export var scaling = true
export var scale_by_node = "sprite"

func _ready():
	for node in get_parent().get_parent().get_children():
		if node is Light2D and node.visible:
			lights.append(node)
	set_process(true)

func _process(delta):
	for light in lights:
		var vector_to = global_position - light.global_position
		var direction = vector_to.normalized()

		# Recalculate shadow's alpha.
		# The closer the light source, the bigger the alpha value
		var max_vector_to = direction * MAX_DIST_VISIBLE
		var alpha_calculated = (max_vector_to / vector_to).x * 2.0
		# printt("ALPHA", alpha_calculated)
		get_material().set_shader_param("alpha_value", alpha_calculated)
		if alpha_calculated < 0.1:
			get_material().set_shader_param("alpha_value", 0.0)
			return

		# Rotate the shadow so it faces the light
		if rotating:
			look_at(light.global_position)
			rotate(PI/2)

		# Scale the shadow according to its distance to light source
		# The closer the light, the shorter its height (down to the minimum size)
		if scaling:
			# printt("direction", direction)
			scale.x = abs(get_parent().get_node(scale_by_node).scale.x) / (1 - abs(direction.x) / 2)
			scale.y = abs(get_parent().get_node(scale_by_node).scale.y) / (1 - abs(direction.y) / 2)
			# printt("scale", scale)

