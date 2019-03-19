tool

extends "terrain_base.gd"

export(Texture) var scales setget set_scales,get_scales
export var bitmaps_scale = Vector2(1,1) setget set_bm_scale,get_bm_scale
export(int, "None", "Scales", "Lightmap") var debug_mode = 1 setget debug_mode_updated
export var scale_min = 0.3
export var scale_max = 1.0

var texture
var img_area
var _texture_dirty = false

var path = null

func set_scales(p_scales):
	scales = p_scales
	_update_texture()

func get_scales():
	return scales

func set_bm_scale(p_scale):
	bitmaps_scale = p_scale
	_update_texture()

func get_bm_scale():
	return bitmaps_scale

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
	if debug_mode == 1:
		if scales != null:
			#texture.create_from_image(scales)
			texture = scales
	else:
		if lightmap != null:
			#texture.create_from_image(lightmap)
			texture = lightmap

	update()

func debug_mode_updated(p_mode):
	debug_mode = p_mode
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
	return p_image.get_pixel(pos.x, pos.y)

func _draw():
	if typeof(texture) == typeof(null):
		return
	if debug_mode == 0:
		return
	#if !get_tree().is_editor_hint():
	#	printt("*********no editor hint")
	#	return
	var scale_vect = bitmaps_scale

	var src = Rect2(0, 0, texture.get_width(), texture.get_height())
	var dst = Rect2(0, 0, texture.get_width() * scale_vect.x, texture.get_height() * scale_vect.y)

	draw_texture_rect_region(texture, dst, src)
	#draw_texture(texture, Vector2(0, 0))

func _ready():
	#path = ImagePathFinder.new()
	_update_texture()


