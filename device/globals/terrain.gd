tool

export(Image) var scales setget set_scales
export(Image) var lightmap setget set_lightmap
export(int, "None", "Scales", "Lightmap") var debug_mode = 1 setget debug_mode_updated
export var modulate = Color(1, 1, 1, 1)
export var scale_min = 0.3
export var scale_max = 1.0
var texture
var img_area


var path = null

func set_scales(p_scales):
	scales = p_scales
	_update_texture()

func set_lightmap(p_lightmap):
	lightmap = p_lightmap
	_update_texture()

func _update_texture():
	if !is_inside_tree():
		return
	if !get_tree().is_editor_hint():
		return

	if debug_mode == 0:
		update()
		return

	texture = ImageTexture.new()
	if debug_mode == 1:
		texture.create_from_image(scales)
	else:
		texture.create_from_image(lightmap)

	update()

func debug_mode_updated(p_mode):
	debug_mode = p_mode
	_update_texture()

func make_local(pos):
	pos = pos - get_pos()
	pos = pos * 1.0 / get_scale()
	if self extends Navigation2D:
		pos = get_closest_point(pos)
	return pos

func make_global(pos):
	pos = pos * get_scale()
	pos = pos + get_pos()
	return pos

func _find_solid(p_dest, dir_x, dir_y):
	if path == null:
		return
	var pos = p_dest
	var size = path.get_size()
	while pos.x >= 0 && pos.x < size.x && pos.y >= 0 && pos.y < size.y:
		if !path.is_solid(pos):
			return pos
		pos.x += dir_x
		pos.y += dir_y

	return Vector2(-1, -1)

func _find_nearest(p_dest):
	var final = Vector2(-1, -1)
	var dist = 1000000

	var dirs_x = [0, 0, 1, -1]
	var dirs_y = [1, -1, 0, 0]
	for i in range(0, 4):
		var s = _find_solid(p_dest, dirs_x[i], dirs_y[i])
		if s.x != -1:
			var d = s.distance_squared_to(p_dest)
			if final.x == -1 || d < dist:
				dist = d
				final = s

	return final


func get_path(p_src, p_dest):
	printt("get path ", p_src, p_dest)
	if !(self extends Navigation2D):
		printt("returning a line")
		return [p_src, p_dest]
	p_src = make_local(p_src)
	p_dest = make_local(p_dest)

	var r_path = get_simple_path(p_src, p_dest, true)
	r_path = Array(r_path)
	for i in range(0, r_path.size()):
		r_path[i] = make_global(r_path[i])
	return r_path

func is_solid(pos):

	pos = pos - get_pos()
	pos = pos * 1.0 / get_scale()

	var closest = get_closest_point(pos)
	return pos == closest

func get_scale_range(r):
	r = scale_min + (scale_max - scale_min) * r
	return Vector2(r, r)

func get_terrain(pos):
	if typeof(scales) == typeof(null) || scales.empty():
		return Color(1, 1, 1, 1)
	return get_pixel(pos, scales)

func _color_mul(a, b):
	var c = Color()
	c.r = a.r * b.r
	c.g = a.g * b.g
	c.b = a.b * b.b
	c.a = a.a * b.a
	return c

func get_light(pos):
	if typeof(lightmap) == typeof(null) || lightmap.empty():
		return modulate
	return _color_mul(get_pixel(pos, lightmap), modulate)

func get_pixel(pos, p_image):

	pos = make_local(pos)

	if pos.x + 1 >= p_image.get_width() || pos.y + 1 >= p_image.get_height() || pos.x < 0 || pos.y < 0:
		return Color()


	var ll = p_image.get_pixel(pos.x, pos.y)
	var ndif = Vector2()
	ndif.x = pos.x - floor(pos.x)
	ndif.y = pos.y - floor(pos.y)
	var ur

	img_area = Rect2(0, 0, p_image.get_width(), p_image.get_height())

	var lr = ll
	if ndif.x > 0 && img_area.has_point(Vector2(pos.x+1, pos.y)):
		lr = p_image.get_pixel(pos.x+1, pos.y)
		#if lr.a < 128:
		#	lr = ll
		ur = lr

	var ul = ll
	if ndif.y > 0 && img_area.has_point(Vector2(pos.x, pos.y+1)):
		ul = p_image.get_pixel(pos.x, pos.y+1)
		#if ul.a < 128:
		#	ul = ll
		ur = ul

	if ndif.x > 0 && ndif.y > 0 && img_area.has_point(Vector2(pos.x+1, pos.y+1)):
		var pix = p_image.get_pixel(pos.x+1, pos.y+1)
		#if pix.a > 128:
		ur = pix

	var bottom = ll.linear_interpolate(lr, ndif.x)
	var top
	if ur != null:
		top = ul.linear_interpolate(ur, ndif.x)
	else:
		top = ul

	var final = bottom.linear_interpolate(top, ndif.y)

	return final

func _draw():
	if typeof(texture) == typeof(null):
		return
	if debug_mode == 0:
		return
	#if !get_tree().is_editor_hint():
	#	printt("*********no editor hint")
	#	return
	var scale = get_scale()

	var rect = Rect2(0, 0, texture.get_width() * scale.x, texture.get_height() * scale.y)
	draw_texture(texture, Vector2(0, 0))

func _ready():
	#path = ImagePathFinder.new()
	_update_texture()


