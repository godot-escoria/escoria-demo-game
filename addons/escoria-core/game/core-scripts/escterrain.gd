tool
extends "res://addons/escoria-core/game/core-scripts/escterrain_base.gd"
class_name ESCTerrain

func get_class():
	return "ESCTerrain"

export var scale_min = 0.3
export var scale_max = 1.0

var current_active_navigation_instance : NavigationPolygonInstance

func _ready():
	var navigation_enabled_found = false
	for n in get_children():
		if n is NavigationPolygonInstance:
			if n.enabled:
				if navigation_enabled_found:
					escoria.report_errors("escterrain.gd:_ready()", ["Multiple NavigationPolygonInstances enabled at the same time."])
				navigation_enabled_found = true
				current_active_navigation_instance = n
	
	if !Engine.is_editor_hint():
		escoria.register_object(self)
	#path = ImagePathFinder.new()
	_update_texture()

func get_scale_range(r):
	r = scale_min + (scale_max - scale_min) * r
	return Vector2(r, r)

func get_terrain(pos):
	if scales == null || scales.get_data().is_empty():
		return Color(1, 1, 1, 1)
	return get_pixel(pos, scales.get_data())

func get_pixel(pos, p_image):
	if pos.x + 1 >= p_image.get_width() || pos.y + 1 >= p_image.get_height() || pos.x < 0 || pos.y < 0:
		return Color(1.0, 0.0, 0.0)

	# `get_pixel()` is slow; this is accurate enough
	# without interpolating neighboring pixels and accounting for fractions
	p_image.lock()
	var pixel = p_image.get_pixel(pos.x, pos.y)
	p_image.unlock()
	return pixel

func _draw():
	if typeof(texture) == typeof(null):
		return
	if !Engine.is_editor_hint():
		return
	if debug_mode == 0:
		return
	var scale_vect = bitmaps_scale

	var src = Rect2(0, 0, texture.get_width(), texture.get_height())
	var dst = Rect2(0, 0, texture.get_width() * scale_vect.x, texture.get_height() * scale_vect.y)

	draw_texture_rect_region(texture, dst, src)
	#draw_texture(texture, Vector2(0, 0))


