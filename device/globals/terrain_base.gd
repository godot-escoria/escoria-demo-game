tool

extends Navigation2D

export(Texture) var lightmap setget set_lightmap,get_lightmap
var lightmap_data  # Did someone do this to suck on purpose? https://github.com/godotengine/godot/issues/13934

export var player_speed_multiplier = 1.0  # Override player speed in current scene
export var player_doubleclick_speed_multiplier = 1.5  # Make the player move faster when doubleclicked
export var lightmap_modulate = Color(1, 1, 1, 1)

func set_lightmap(p_lightmap):
	var need_init = (lightmap != p_lightmap) or (lightmap and not lightmap_data)

	lightmap = p_lightmap

	# It's bad enough a new copy is created when reading a pixel, we don't
	# also need to get the data for every read to make yet another copy
	if need_init:
		if lightmap_data:
			lightmap_data.unlock()
		lightmap_data = lightmap.get_data()
		lightmap_data.lock()

	_update_texture()

func get_lightmap():
	return lightmap

func make_local(pos):
	pos = pos - get_position()
	pos = pos * 1.0 / get_scale()
	if self is Navigation2D:
		pos = get_closest_point(pos)
	return pos

func make_global(pos):
	pos = pos * get_scale()
	pos = pos + get_position()
	return pos

func get_path(p_src, p_dest):
	# printt("get path ", p_src, p_dest)
	if !(self is Navigation2D):
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
	pos = pos - get_position()
	pos = pos * 1.0 / get_scale()

	var closest = get_closest_point(pos)
	return pos == closest

func _color_mul(a, b):
	var c = Color()
	c.r = a.r * b.r
	c.g = a.g * b.g
	c.b = a.b * b.b
	c.a = a.a * b.a
	return c

func get_light(pos):
	if typeof(lightmap) == typeof(null) || lightmap.get_data().is_empty():
		return lightmap_modulate

	return _color_mul(get_pixel(pos, lightmap_data), lightmap_modulate)

