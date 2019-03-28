tool

extends KinematicBody2D

var task
var walk_destination
var animation
var vm  # A tool script cannot refer to singletons in Godot
var terrain
var terrain_is_scalenodes
var walk_path
var walk_context
var moved
var path_ofs
export var speed = 300
export var v_speed_damp = 1.0
export(Script) var animations
#warning-ignore:unused_class_variable
export(Color) var dialog_color = null
var last_deg = null
var last_dir = 0
var last_scale
var pose_scale = 1
var params_queue

export var telekinetic = false

var check_maps   # set by lightmap_area.gd

var orig_speed

var anim_notify = null
var anim_scale_override = null
var sprites = []
export var placeholders = {}

# Use `interact_status` to prevent player from moving past target when interacting.
# This appears to happen because Godot doesn't discern a click from a double click
# until the second click happens, by which time the player is already underway to
# an invalid position.
var interact_status = 0
enum interact_statuses {INTERACT_NONE, INTERACT_STARTED, INTERACT_WALKING}

func get_camera_pos():
	if has_node("camera_pos"):
		return $"camera_pos".global_position

	return global_position

func get_dialog_pos():
	if has_node("dialog_pos"):
		return $"dialog_pos".global_position

	return global_position

func resolve_angle_to(obj):
	# Set `last_deg` and `last_dir` as they are globals
	var angle = self.position.angle_to_point(obj.position) * -1
	last_deg = vm._get_deg_from_rad(angle)
	# printt("Resolve angle from ", self.position, " to ", obj.position, ":", last_deg)
	last_dir = vm._get_dir_deg(last_deg, animations)

func set_active(p_active):
	if p_active:
		show()
	else:
		hide()

func walk_to(pos, context = null):
	if not terrain:
		return walk_stop(get_position())

	if interact_status == interact_statuses.INTERACT_WALKING:
		return
	if interact_status == interact_statuses.INTERACT_STARTED:
		interact_status = interact_statuses.INTERACT_WALKING
	walk_path = terrain.get_terrain_path(get_position(), pos)
	walk_context = context
	if walk_path.size() == 0:
		task = null
		walk_stop(get_position())
		set_process(false)
		return
	moved = true
	walk_destination = walk_path[walk_path.size()-1]
	if terrain.is_solid(pos):
		walk_destination = walk_path[walk_path.size()-1]
	path_ofs = 0.0
	task = "walk"
	set_process(true)

func walk(pos, p_speed, context = null):
	if p_speed:
		orig_speed = speed
		speed = p_speed
	walk_to(pos, context)

func anim_finished(anim_name):
	# Ignore the signal if the previous animation finished while we're actually playing another one
	if animation.get_current_animation() and anim_name != animation.get_current_animation():
		# printt("player: anim_finished: ignore", anim_name, animation.get_current_animation())
		return

	if anim_notify != null:
		vm.finished(anim_notify)
		anim_notify = null

	if anim_scale_override != null:
		.set_scale(.get_scale() * anim_scale_override)
		anim_scale_override = null

	animation.play(animations.idles[last_dir])
	pose_scale = animations.idles[last_dir + 1]
	_update_terrain()

func set_speaking(p_speaking):
	if p_speaking:
		animation.play(animations.speaks[last_dir])
		pose_scale = animations.speaks[last_dir + 1]
	else:
		animation.play(animations.idles[last_dir])
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
	if not animation:
		vm.report_errors("player", ["Animation not found for play_anim"])
	if not animation.has_animation(p_anim):
		vm.report_errors("player", [animation.name + " does not contain " + p_anim])

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
		var s = .get_scale()
		.set_scale(s * p_flip)
		anim_scale_override = p_flip
	else:
		anim_scale_override = null

	if p_reverse:
		animation.play(p_anim, -1, -1, true)
	else:
		animation.play(p_anim)

	anim_notify = p_notify
	var dir = _find(p_anim, animations.directions, p_flip.x)
	if dir == -1:
		dir = _find(p_anim, animations.idles, p_flip.x)
	if dir != -1:
		last_dir = dir

	set_process(false)

func interact(p_params):
	interact_status = interact_statuses.INTERACT_STARTED
	var obj = p_params[0]
	var action = p_params[1]
	var pos
	if obj.has_method("get_interact_pos"):
		pos = obj.get_interact_pos()
	else:
		pos = obj.get_global_position()

	# Check if we are using an item with another, lest we fall back to fallbacks' :use
	# so this reworks action to match `:use inv_ice_cream`
	if p_params.size() > 2 and p_params[2]:
		var target = p_params[2].global_id
		action += " " + target

	# It's safe to assume false, because it most likely gets reset
	# or we pass control over to fallbacks in game.interact()
	var do_walk = false
	var telekinetic_action = false
	if action in obj.event_table:
		var ev_flags = obj.event_table[action]["ev_flags"]

		# Triggering a telekinetic default action by double-clicking will set
		# the player walking, so stop as immediately as possible. It would be
		# better if Godot waited a while to see if the first click of a double-click
		# is a click or should it be handled as a double-click.
		if not "TK" in ev_flags:
			do_walk = true
		else:
			telekinetic_action = true
			if walk_path:
				walk_stop(walk_path[0])
			else:
				walk_stop(get_position())

		if not walk_context:
			walk_context = {"fast": true}
		else:
			walk_context["fast"] = true
			do_walk = true

	if (not telekinetic and do_walk) and get_global_position().distance_to(pos) > 10:
		# It's important to set the queue before walking, so it
		# is in effect until walk_stop() has to reset the queue.
		params_queue = p_params
		walk_to(pos, walk_context)
	else:
		if animations.dir_angles.size() > 0:
			if not telekinetic_action and obj.interact_angle != -1:
				last_dir = vm._get_dir_deg(obj.interact_angle, animations)
			else:
				resolve_angle_to(obj)
			animation.play(animations.idles[last_dir])
			pose_scale = animations.idles[last_dir + 1]
			_update_terrain()
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "interact", p_params)

func slide_to(pos, context = null):
       # Assume a straight line, and leverage some walk functionality
       walk_path = [get_position(), pos]
       walk_context = context
       if walk_path.size() == 0:
               walk_stop(get_position())
               set_process(false)
               task = null
               return

       moved = true

       walk_destination = walk_path[walk_path.size()-1]

       path_ofs = 0.0
       task = "slide"
       set_process(true)

func slide(pos, p_speed, context = null):
	if p_speed:
		orig_speed = speed
		speed = p_speed
	slide_to(pos, context)

func walk_stop(pos):
	# Notify exits of stop position
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "exit", "stopped_at", pos)

	set_position(pos)
	interact_status = interact_statuses.INTERACT_NONE
	walk_path = []

	if orig_speed:
		speed = orig_speed
		orig_speed = null

	task = null
	moved = false
	set_process(false)
	if params_queue != null:
		if animations.dir_angles.size() > 0:
			if params_queue[0].interact_angle == -1:
				resolve_angle_to(params_queue[0])
			else:
				last_dir = vm._get_dir_deg(params_queue[0].interact_angle, animations)
			animation.play(animations.idles[last_dir])
			pose_scale = animations.idles[last_dir + 1]
			_update_terrain()
		else:
			animation.play(animations.idles[last_dir])
			pose_scale = animations.idles[last_dir + 1]
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "interact", params_queue)
		# Clear params queue to prevent the same action from being triggered again
		params_queue = null
	else:
		animation.play(animations.idles[last_dir])
		pose_scale = animations.idles[last_dir + 1]
	_update_terrain()
	if walk_context != null:
		vm.finished(walk_context)
		walk_context = null


func _notification(what):
	if !is_inside_tree() || !Engine.is_editor_hint():
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
	z_index = pos.y if pos.y <= VisualServer.CANVAS_ITEM_Z_MAX else VisualServer.CANVAS_ITEM_Z_MAX

	var color
	if terrain_is_scalenodes:
		last_scale = terrain.get_terrain(pos)
		last_scale.x *= pose_scale
		set_scale(last_scale)
	elif check_maps:
		color = terrain.get_terrain(pos)
		var scal = terrain.get_scale_range(color.b)
		scal.x = scal.x * pose_scale
		if scal != get_scale():
			last_scale = scal
			.set_scale(last_scale)

	if check_maps:
		color = terrain.get_light(pos)

	if color:
		for s in sprites:
			s.set_modulate(color)

func _process(time):
	if task == "walk" or task == "slide":
		var pos = get_position()
		var old_pos = pos
		var next
		if walk_path.size() > 1:
			next = walk_path[path_ofs + 1]
		else:
			next = walk_path[path_ofs]

		var dist = speed * time * pow(last_scale.x, 2) * terrain.player_speed_multiplier
		if walk_context and "fast" in walk_context and walk_context.fast:
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

		var angle = (old_pos.angle_to_point(pos)) * -1
		set_position(pos)

		if task == "walk":
			last_deg = vm._get_deg_from_rad(angle)
			last_dir = vm._get_dir_deg(last_deg, animations)

			if animation.get_current_animation() != animations.directions[last_dir]:
				animation.play(animations.directions[last_dir])
			pose_scale = animations.directions[last_dir+1]

		_update_terrain()
	else:
		moved = false


func teleport(obj, angle=null):
	if animations.dir_angles.size() > 0 and not angle:
		if "interact_angle" in obj and obj.interact_angle != -1:
			last_deg = obj.interact_angle
			last_dir = vm._get_dir_deg(obj.interact_angle, animations)
			animation.play(animations.idles[last_dir])
			pose_scale = animations.idles[last_dir + 1]
	elif angle:
		set_angle(angle)

	var pos
	if obj.has_method("get_interact_pos"):
		pos = obj.get_interact_pos()
	else:
		pos = obj.get_global_position()

	set_position(pos)
	moved = true
	_update_terrain()

func set_state(costume):
	# Set a costume-state by changing the AnimationPlayer.
	if has_node(costume):
		animation = get_node(costume)
	else:
		vm.report_errors("player", ["Costume AnimationPlayer '" + costume + "' not found"])

	animation.play(animations.idles[last_dir])

func teleport_pos(x, y, angle=null):
	set_position(Vector2(x, y))
	if angle:
		set_angle(angle)
	moved = true
	_update_terrain()

func turn_to(deg):
	if deg < 0 or deg > 360:
		vm.report_errors("player", ["Invalid degree to turn to " + str(deg)])

	moved = true

	last_deg = deg
	last_dir = vm._get_dir_deg(deg, animations)

	if animation.get_current_animation() != animations.directions[last_dir]:
		animation.play(animations.directions[last_dir])
	pose_scale = animations.directions[last_dir+1]
	_update_terrain()

func set_angle(deg):
	if deg < 0 or deg > 360:
		# Compensate for savegame files during a broken version of Escoria
		if vm.loading_game:
			vm.report_warnings("player", ["Reset invalid degree " + str(deg)])
			deg = 0
		else:
			vm.report_errors("player", ["Invalid degree to turn to " + str(deg)])

	moved = true

	last_deg = deg
	last_dir = vm._get_dir_deg(deg, animations)

	# The player may have a state animation from before, which would be
	# resumed, so we immediately force the correct idle animation
	if animation.get_current_animation() != animations.idles[last_dir]:
		animation.play(animations.idles[last_dir])
	pose_scale = animations.idles[last_dir+1]
	_update_terrain()


func _find_sprites(p = null):
	if p is CanvasItem:
		sprites.push_back(p)
	for i in range(0, p.get_child_count()):
		_find_sprites(p.get_child(i))

func _ready():

	if has_node("../terrain"):
		terrain = $"../terrain"
		terrain_is_scalenodes = terrain is preload("terrain_scalenodes.gd")

	_find_sprites(self)

	# Set the player up for z-index, scale, light etc, update later when moving
	_update_terrain()

	if Engine.is_editor_hint():
		return

	vm = $"/root/vm"

	if has_node("default"):
		animation = $"default"

		if not animations:
			vm.report_errors("player", ["Animations not set for player."])
	else:
		vm.report_errors("player", ["No default AnimationPlayer found"])

	for child in get_children():
		if child is AnimationPlayer:
			child.connect("animation_finished", self, "anim_finished")

	vm.register_object("player", self)

	last_scale = .get_scale()
	set_process(true)
