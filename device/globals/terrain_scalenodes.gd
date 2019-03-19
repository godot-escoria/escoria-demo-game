tool

extends "terrain_base.gd"

export(int, "None", "Lightmap") var debug_mode = 0 setget debug_mode_updated

var _texture_dirty = false
var texture

var scale_nodes = []

onready var scale_min = $"scale_min"
onready var scale_max = $"scale_max"

func debug_mode_updated(p_mode):
	debug_mode = p_mode

	_update_texture()

func _update_texture():
	if _texture_dirty:
		return

	_texture_dirty = true
	call_deferred("_do_update_texture")

func _do_update_texture():
	_texture_dirty = false
	if !is_inside_tree():
		return
	if !Engine.is_editor_hint():
		return

	if debug_mode == 0:
		update()
		return

	texture = ImageTexture.new()

	if lightmap != null:
		#texture.create_from_image(lightmap)
		texture = lightmap

	update()

static func sort_by_y(a, b):
	return a.global_position.y < b.global_position.y

# Return a "scale range" immediately based on the interpolated scale size
func get_terrain(pos):
	# printt("Called", pos)
	var prev
	var next
	var prev_target
	var node_target
	for i in range(1, scale_nodes.size()):
		prev = scale_nodes[i - 1]
		next = scale_nodes[i]

		if prev.global_position.y < pos.y and pos.y < next.global_position.y:
			# printt("1:", prev.global_position.y, " < ", pos.y, " and ", pos.y, " < ", next.global_position.y)
			prev_target = prev.target_scale.y
			node_target = next.target_scale.y
			break

	var nodes_dist = next.global_position.y - prev.global_position.y
	var interp_dist = (pos.y - prev.global_position.y) / nodes_dist

	var y_1 = Vector2(0, prev_target)
	var y_2 = Vector2(0, node_target)

	var interp = y_1.linear_interpolate(y_2, interp_dist)

	return Vector2(interp.y, interp.y)

func get_pixel(pos, p_image):
	if pos.x + 1 >= p_image.get_width() || pos.y + 1 >= p_image.get_height() || pos.x < 0 || pos.y < 0:
		return Color(1.0, 0.0, 0.0)

	# `get_pixel()` is slow; this is accurate enough
	# without interpolating neighboring pixels and accounting for fractions
	return p_image.get_pixel(pos.x, pos.y)

func _draw():
	if not texture:
		return

	if debug_mode == 0:
		return

	draw_texture(texture, Vector2(0, 0))

func _ready():
	for c in get_children():
		if c is preload("scalenode.gd"):
			scale_nodes.push_back(c)

	scale_nodes.sort_custom(self, "sort_by_y")
	scale_nodes.push_front(scale_min)
	scale_nodes.push_back(scale_max)

