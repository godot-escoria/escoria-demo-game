tool

extends KinematicBody2D

var task
var walk_destination
var animation
var animation_is_spine
var vm  # A tool script cannot refer to singletons in Godot
var terrain
var walk_path
var walk_context
var path_ofs
export var speed = 300
export var v_speed_damp = 1.0
export(Script) var animations
export(Color) var dialog_color = null
var last_dir = 0
var last_scale
var pose_scale = 1
var params_queue
var camera
export var camera_limits = Rect2()

export var telekinetic = false

var anim_notify = null
var anim_scale_override = null
var sprites = []
export var placeholders = {}

func set_active(p_active):
	if p_active:
		show()
	else:
		hide()

func walk_to(pos, context = null):
	walk_path = terrain.get_path(get_position(), pos)
	walk_context = context
	if walk_path.size() == 0:
		task = null
		params_queue = null
		walk_stop(get_position())
		set_process(false)
		return
	walk_destination = walk_path[walk_path.size()-1]
	if terrain.is_solid(pos):
		walk_destination = walk_path[walk_path.size()-1]
	path_ofs = 0.0
	task = "walk"
	set_process(true)
	params_queue = null

func walk(pos, speed, context = null):
	walk_to(pos, context)

func anim_finished(anim_name):
	# Spine will call this with track_number instead of animation name,
	# and only track 0 is supported

	# This prevents Spine from breaking and restarting a loop, to
	# avoid a glitch in the walk animation
	if animation_is_spine and task == "walk":
		return

	if anim_notify != null:
		vm.finished(anim_notify)
		anim_notify = null

	if anim_scale_override != null:
		set_scale(get_scale() * anim_scale_override)
		anim_scale_override = null

	# Spine needs to add the idle animation to the queue, Godot would just play it
	if !animation_is_spine:
		_animation_play({"name": animations.idles[last_dir]})
	else:
		animation.add(animations.idles[last_dir], true)

	pose_scale = animations.idles[last_dir + 1]
	_update_terrain()

func set_speaking(p_speaking):
	if p_speaking:
		_animation_play({"name": animations.speaks[last_dir]})
		pose_scale = animations.speaks[last_dir + 1]
	else:
		_animation_play({"name": animations.idles[last_dir], "loop": true})
		pose_scale = animations.idles[last_dir + 1]
	_update_terrain()

func _find(p_val, p_array, p_flip):
	var i = 0
	for v in p_array:
		if typeof(v) == typeof(p_val) && v == p_val:
			if p_flip == null:
				return i
			else:
				if p_array[i+1] == p_flip:
					return i

		i += 1
	return -1

func anim_get_ph_paths(p_anim):
	if !(p_anim in placeholders):
		return null

	var ret = []
	for p in placeholders[p_anim]:
		var n = get_node(p)
		if !(n is InstancePlaceholder):
			continue
		ret.push_back(n.get_instance_path())
	return ret

func play_anim(p_anim, p_notify = null, p_reverse = false, p_flip = null):
	if p_notify != null && (!animation || !animation.has_animation(p_anim)):
		vm.finished(p_notify)
		return

	if p_anim in placeholders:
		for npath in placeholders[p_anim]:
			var node = get_node(npath)
			if !(node is InstancePlaceholder):
				continue
			var path = node.get_instance_path()
			var res = vm.res_cache.get_resource(path)
			node.replace_by_instance(res)
			_find_sprites(get_node(npath))

	pose_scale = 1
	_update_terrain()
	if p_flip != null:
		var s = get_scale()
		set_scale(s * p_flip)
		anim_scale_override = p_flip
	else:
		anim_scale_override = null

	if p_reverse:
		if animation_is_spine:
			# Spine is too "advanced" to have a simple mechanism for reversing an animation
			# https://github.com/EsotericSoftware/spine-runtimes/issues/203 probably related
			printt("Not implemented")
			assert(0)
		_animation_play({"name": p_anim, "custom_blend": -1, "custom_speed": -1.0, "from_end": true})
	else:
		_animation_play({"name": p_anim})
		if animation_is_spine:
			animation.add(animations.idles[last_dir], true)

	anim_notify = p_notify
	var dir = _find(p_anim, animations.directions, p_flip.x)
	if dir == -1:
		dir = _find(p_anim, animations.idles, p_flip.x)
	if dir != -1:
		last_dir = dir

	set_process(false)

func interact(p_params):
	var pos
	if p_params[0].has_node("interact_pos"):
		pos = p_params[0].get_node("interact_pos").get_global_position()
	else:
		pos = p_params[0].get_global_position()
	if !telekinetic && get_global_position().distance_to(pos) > 10:
		walk_to(pos)
		params_queue = p_params
	else:
		if animations.dir_angles.size() > 0 && p_params[0].interact_angle != -1:
			last_dir = _get_dir_deg(p_params[0].interact_angle)
			_animation_play({"name": animations.idles[last_dir], "loop": true})
			pose_scale = animations.idles[last_dir + 1]
			_update_terrain()
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "interact", p_params)

func walk_stop(pos):
	printt("walk_stop at ", pos)
	# Notify exits of stop position
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "exit", "stopped_at", pos)

	set_position(pos)
	walk_path = []
	task = null
	set_process(false)
	if typeof(params_queue) != typeof(null):
		if animations.dir_angles.size() > 0 && params_queue[0].interact_angle != -1:
			last_dir = _get_dir_deg(params_queue[0].interact_angle)
			_animation_play({"name": animations.idles[last_dir], "loop": true})
			pose_scale = animations.idles[last_dir + 1]
			_update_terrain()
		else:
			_animation_play({"name": animations.idles[last_dir], "loop": true})
			pose_scale = animations.idles[last_dir + 1]
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "interact", params_queue)
	else:
		_animation_play({"name": animations.idles[last_dir], "loop": true})
		pose_scale = animations.idles[last_dir + 1]
	_update_terrain()
	if walk_context != null:
		vm.finished(walk_context)
		walk_context = null

func _get_dir(angle):
	var deg = rad2deg(angle) + 180
	return _get_dir_deg(deg)

func _get_dir_deg(deg):
	var dir = 0
	var i = 0
	for ang in animations.dir_angles:
		if deg < ang:
			dir = i
			break
		i+=2
	return dir


func _notification(what):
	if !get_tree() || !Engine.is_editor_hint():
		return

	if what == CanvasItem.NOTIFICATION_TRANSFORM_CHANGED:
		call_deferred("_editor_transform_changed")

func _editor_transform_changed():
	_update_terrain()
	_check_bounds()

func _check_bounds():
	if !terrain:
		return

	#printt("checking bouds for pos ", get_position(), terrain.is_solid(get_position()))
	if terrain.is_solid(get_position()):
		if has_node("terrain_icon"):
			get_node("terrain_icon").hide()
	else:
		if !has_node("terrain_icon"):
			var node = Sprite.new()
			var tex = load("res://globals/terrain.png")
			node.set_texture(tex)
			add_child(node)
			node.set_name("terrain_icon")
		get_node("terrain_icon").show()

func _update_terrain():
	if !terrain:
		return

	var pos = get_position()
	set_z_index(pos.y)
	var color = terrain.get_terrain(pos)
	var scal = terrain.get_scale_range(color.b)
	scal.x = scal.x * pose_scale
	#if scale != last_scale:
	if scal != get_scale():
		last_scale = scal
		set_scale(last_scale)
	color = terrain.get_light(pos)
	for s in sprites:
		s.set_modulate(color)

func _animation_play(args):
	if !animation:
		return

	assert(typeof(args) == TYPE_DICTIONARY)

	## Then tackle the hard part, though name must always be present
	var name = args["name"]

	if !animation_is_spine:
		# play(String name=”“, float custom_blend=-1, float custom_speed=1.0, bool from_end=false)
		var custom_blend = args["custom_blend"] if args.has("custom_blend") else -1
		var custom_speed = args["custom_speed"] if args.has("custom_speed") else 1.0
		var from_end = args["from_end"] if args.has("from_end") else false

		animation.play(name, custom_blend, custom_speed, from_end)
	else:
		# play(const String &p_name, bool p_loop, int p_track, int p_delay)
		var loop = args["loop"] if args.has("loop") else false
		var track = args["track"] if args.has("track") else 0
		var delay = args["delay"] if args.has("delay") else 0

		animation.play(name, loop, track, delay)

func _animation_get_current_animation():
	if !animation:
		return

	# XXX: Spine defaults to track 0
	return animation.get_current_animation()

func _process(time):
	if task == "walk":
		var pos = get_position()
		var old_pos = pos
		var next
		if walk_path.size() > 1:
			next = walk_path[path_ofs + 1]
		else:
			next = walk_path[path_ofs]

		var dist = speed * time * pow(last_scale.x, 2) * terrain.player_speed_multiplier
		if walk_context and walk_context.fast:
			dist *= terrain.player_doubleclick_speed_multiplier
		var dir = (next - pos).normalized()

		# assume that x^2 + y^2 == 1, apply v_speed_damp the y axis
		#printt("dir before", dir)
		dir = dir * (dir.x * dir.x +  dir.y * dir.y * v_speed_damp)
		#printt("dir after", dir, dist)

		var new_pos
		if pos.distance_to(next) < dist:
			new_pos = next
			path_ofs += 1
		else:
			new_pos = pos + dir * dist

		if path_ofs >= walk_path.size() - 1:
			walk_stop(walk_destination)
			return

		pos = new_pos

		var angle = (old_pos.angle_to_point(pos) - PI/2) * -1
		set_position(pos)

		last_dir = _get_dir(angle)

		var current_animation = _animation_get_current_animation()

		if current_animation != animations.directions[last_dir]:
			_animation_play({"name": animations.directions[last_dir], "loop": true})
		pose_scale = animations.directions[last_dir+1]

	_update_terrain()


func teleport(obj):
	if animations.dir_angles.size() > 0 && obj.interact_angle != -1:
		last_dir = _get_dir(obj.interact_angle)
		_animation_play({"name": animations.idles[last_dir], "loop": true})
		pose_scale = animations.idles[last_dir + 1]

	var pos
	if obj.has_node("interact_pos"):
		pos = obj.get_node("interact_pos").get_global_position()
	else:
		pos = obj.get_global_position()

	set_position(pos)
	_update_terrain()

func set_state(name):
	pass

func teleport_pos(x, y):
	set_position(Vector2(x, y))
	_update_terrain()


func _find_sprites(p = null):
	if p is Sprite || p is AnimatedSprite || p.get_class() == "Spine":
		sprites.push_back(p)
	for i in range(0, p.get_child_count()):
		_find_sprites(p.get_child(i))

func _ready():

	if get_parent().has_node("terrain"):
		terrain = get_parent().get_node("terrain")

	_find_sprites(self)
	if Engine.is_editor_hint():
		return

	animation = $"animation"
	vm = $"/root/vm"
	vm.register_object("player", self)
	#_update_terrain();
	if animation:
		assert(animations)

		# Spine support
		animation_is_spine = animation.get_class() == "Spine"
		if animation_is_spine:
			animation.connect("animation_end", self, "anim_finished")
		else:
			animation.connect("animation_finished", self, "anim_finished")

	last_scale = get_scale()
	set_process(true)
