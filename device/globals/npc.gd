tool

extends KinematicBody2D

signal left_click_on_npc
signal left_dblclick_on_npc
signal right_click_on_npc
signal mouse_enter_npc
signal mouse_exit_npc

#warning-ignore:unused_class_variable
export var global_id = ""                                  # API property
#warning-ignore:unused_class_variable
export(String, FILE, ".esc") var events_path = ""          # API property
export var active = true setget set_active,get_active

export var tooltip = ""
export var action = ""

export(NodePath) var interact_position = null
#warning-ignore:unused_class_variable
export var use_combine = false           # game.gd
#warning-ignore:unused_class_variable
export var use_action_menu = true        # game.gd

#warning-ignore:unused_class_variable
export(int, -1, 360) var interact_angle = -1
#warning-ignore:unused_class_variable
export(Color) var dialog_color = null
export(Script) var animations
export var talk_animation = "talk"
export var placeholders = {}
export var dynamic_z_index = true
export var speed = 300
export var scale_on_map = false
export var light_on_map = false setget set_light_on_map

var check_maps   # set by lightmap_area.gd

var vm  # A tool script cannot refer to singletons in Godot

var area

var orig_speed

var anim_notify = null
var anim_scale_override = null
var ui_anim = null

var clicked = false
var interact_pos
var camera_pos
var terrain
var terrain_is_scalenodes
var walk_path
var walk_context
var moved
var last_scale = Vector2(1, 1)
var last_deg = null
var last_dir = 0
var animation
var state = ""
var walk_destination
var path_ofs
var pose_scale = 1
var task
var sprites = []
var audio

# Godot doesn't do doubleclicks so we must
var last_lmb_dt = 0
var waiting_dblclick = false

# This'll contain a highlight tooltip if `tooltip_pos` is set as a child
var highlight_tooltip

var event_table = {}

var width = float(ProjectSettings.get("display/window/size/width"))
var height = float(ProjectSettings.get("display/window/size/height"))

func run_event(p_ev):
	vm.emit_signal("run_event", p_ev)

func activate(p_action, p_param = null):
	if p_param != null:
		p_action = p_action + " " + p_param.global_id

	if p_action in event_table:
		run_event(event_table[p_action])
	else:
		return false
	return true

func set_active(p_active):
	active = p_active
	if p_active:
		show()
	else:
		hide()

func set_interactive(p_interactive):
	self.area.visible = p_interactive

func get_active():
	return active

func get_dialog_pos():
	if has_node("dialog_pos"):
		return $"dialog_pos".global_position

	return global_position

func get_interact_pos():
	if interact_pos:
		return interact_pos.global_position

	return global_position

func get_camera_pos():
	if camera_pos:
		return camera_pos.global_position

	return global_position

#warning-ignore:unused_argument
func anim_finished(anim_name):
	# TODO use parameter here?
	if anim_notify != null:
		vm.finished(anim_notify)
		anim_notify = null

	if anim_scale_override != null:
		set_scale(get_scale() * anim_scale_override)
		anim_scale_override = null

	# Although states are permanent until changed, the underlying animations are not,
	# so we must re-set the state for the appearance of permanence
	set_state(state, true)

	if animations and "idles" in animations:
		pose_scale = animations.idles[last_dir + 1]
		_update_terrain()


	#return is_visible()

func get_action():
	return action

func mouse_enter():
	_check_focus(true, false)
	emit_signal("mouse_enter_npc", self)

func mouse_exit():
	_check_focus(false, false)
	emit_signal("mouse_exit_npc", self)

func area_input(_viewport, event, _shape_idx):
	# TODO: Expand this for other input events than mouse
	if event is InputEventMouseButton || event.is_action("ui_accept"):
		if event.is_pressed():
			clicked = vm.hover_stack.front() == self

			var ev_pos = get_global_mouse_position()
			if event.is_action("game_general"):
				if last_lmb_dt <= vm.DOUBLECLICK_TIMEOUT:
					emit_signal("left_dblclick_on_npc", self, ev_pos, event)
					last_lmb_dt = 0
					waiting_dblclick = null
				else:
					last_lmb_dt = 0
					waiting_dblclick = [ev_pos, event]

			elif event.is_action("game_rmb"):
				emit_signal("right_click_on_npc", self, ev_pos, event)
			_check_focus(true, true)

func _check_focus(focus, pressed):
	if has_node("_focus_in"):
		if focus:
			get_node("_focus_in").show()
		else:
			get_node("_focus_in").hide()

	if has_node("_pressed"):
		if pressed:
			get_node("_pressed").show()
		else:
			get_node("_pressed").hide()

func get_tooltip(hint=null):
	if not tooltip:
		return null

	# if `development_lang` matches `text_lang`, don't translate
	if TranslationServer.get_locale() == ProjectSettings.get_setting("escoria/platform/development_lang"):
		if not global_id and ProjectSettings.get_setting("escoria/platform/force_tooltip_global_id"):
			vm.report_errors("npc", ["Missing global_id in npc with tooltip '" + tooltip + "'"])
		return tooltip

	# Otherwise try to return the translated tooltip
	var tooltip_identifier = global_id + ".tooltip"
	if hint:
		tooltip_identifier += "." + hint

	var translated = tr(tooltip_identifier)

	# Try again if there's no translation for this hint
	if translated == "\"":
		tooltip_identifier = global_id + ".tooltip"
		translated = tr(tooltip_identifier)

	# But if translation isn't found, ensure it can be translated and return placeholder
	if translated == tooltip_identifier:
		if not global_id and ProjectSettings.get_setting("escoria/platform/force_tooltip_global_id"):
			vm.report_errors("npc", ["Missing global_id in npc with tooltip '" + tooltip + "'"])

		return tooltip_identifier

	return translated

func show_highlight():
	if not self.visible:
		return

	if not self.area.visible:
		return

	if not has_node("tooltip_pos"):
		return

	highlight_tooltip = vm.tooltip.duplicate()
	assert(highlight_tooltip != vm.tooltip)

	var tt_pos = $"tooltip_pos".global_position
	var tt_text = get_tooltip()

	highlight_tooltip.highlight_only = true
	highlight_tooltip.follow_mouse = false
	highlight_tooltip.text = tt_text

	tt_pos = vm.camera.zoom_transform.xform(tt_pos)

	# Bail out if we're hopelessly out-of-view
	if tt_pos.x < 0 or tt_pos.x > width or tt_pos.y < 0 or tt_pos.y > height:
		highlight_tooltip.free()
		highlight_tooltip = null
		return

	vm.tooltip.get_parent().add_child(highlight_tooltip)

	highlight_tooltip.set_position(tt_pos)

	highlight_tooltip.show()

func hide_highlight():
	if not highlight_tooltip:
		return

	assert(highlight_tooltip.visible)

	highlight_tooltip.hide()
	highlight_tooltip.free()
	highlight_tooltip = null

func global_changed(name):
	var ev = "global_changed "+name
	if ev in event_table:
		run_event(event_table[ev])
	elif "global_changed" in event_table:
		run_event(event_table.global_changed)

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
	if p_notify == null and (!animation or !animation.has_animation(p_anim)):
		print("skipping cut scene '", p_anim, "'")
		vm.finished(p_notify)
		#_debug_states()
		return

	if p_anim in placeholders:
		for npath in placeholders[p_anim]:
			var node = get_node(npath)
			if !node is InstancePlaceholder:
				continue
			var path = node.get_instance_path()
			var res = vm.res_cache.get_resource(path)
			node.replace_by_instance(res)
			_find_sprites(get_node(npath))
	if p_flip != null:
		var s = get_scale()
		set_scale(s * p_flip)
		anim_scale_override = p_flip
	else:
		anim_scale_override = null

	if p_reverse:
		animation.play(p_anim, -1, -1, true)
	else:
		animation.play(p_anim)
	anim_notify = p_notify

	#_debug_states()

func play_snd(p_snd, p_loop=false):
	if !audio:
		vm.report_errors("npc", ["play_snd called with no audio node"])
		return

	var resource = load(p_snd)
	if !resource:
		vm.report_errors("npc", ["play_snd resource not found " + p_snd])
		return

	audio.stream = resource
	audio.stream.set_loop(p_loop)
	audio.play()

	#_debug_states()

func set_speaking(p_speaking):
	printt("npc set speaking! ", global_id, p_speaking, state)
	#print_stack()
	if !animation:
		return
	if talk_animation == "":
		return
	if p_speaking:
		if animation.has_animation(talk_animation):
			animation.play(talk_animation)
			animation.seek(0, true)
	else:
		set_state(state, true)
		if animations and "idles" in animations:
			pose_scale = animations.idles[last_dir + 1]
	_update_terrain()

func set_state(p_state, p_force = false):
	if state == p_state && !p_force:
		return

	# printt("set state ", "global_id: ", global_id, "state: ", state, "p_state: ", p_state, "p_force: ", p_force)

	state = p_state

	if animation != null:
		# Though calling `.play()` probably stops the animation, be safe.
		animation.stop()
		if animation.has_animation(p_state):
			animation.play(p_state)

func teleport(obj, angle=null):
	set_position(obj.global_position)
	if angle:
		set_angle(angle)
	moved = true
	_update_terrain(true)

func teleport_pos(x, y, angle=null):
	set_position(Vector2(x, y))
	if angle:
		set_angle(angle)
	moved = true
	_update_terrain(true)

func _update_terrain(need_z_update=false):
	# Objects in the scene tree will issue errors unless this is conditional
	if not terrain:
		return

	var pos = get_position()

	if dynamic_z_index and need_z_update:
		z_index = pos.y if pos.y <= VisualServer.CANVAS_ITEM_Z_MAX else VisualServer.CANVAS_ITEM_Z_MAX

	if !scale_on_map && !light_on_map:
		return

	var scale_range
	if terrain_is_scalenodes:
		scale_range = terrain.get_terrain(pos)
	elif check_maps:
		var color = terrain.get_terrain(pos)
		scale_range = terrain.get_scale_range(color.b)

	if scale_on_map and scale_range != get_scale():
		# Check if `interact_pos` is a child of ours, and if so,
		# take a backup of the global position, because it will be affected by scaling.
		var interact_global_position
		if has_node("interact_pos"):
			interact_global_position = interact_pos.get_global_position()

		# Same for camera_pos
		var camera_global_position
		if has_node("camera_pos"):
			camera_global_position = camera_pos.get_global_position()

		self.scale = scale_range

		# If `interact_pos` is a child, it was affected by scaling, so reset it
		# to the expected location.
		if interact_global_position:
			interact_pos.global_position = interact_global_position

		# And camera position
		if camera_global_position:
			camera_pos.global_position = camera_global_position

	if light_on_map and check_maps:
		var c = terrain.get_light(pos)
		if c:
			modulate(c)

	# The npc's - as the player's - `animations` define the direction
	# as 1 or -1. This is stored as `pose_scale` and the easiest way
	# to flip a node is multiply its x-axis scale.
	if pose_scale == -1 and $"sprite".scale.x > 0:
		$"sprite".scale.x *= pose_scale
		$"area".scale.x *= pose_scale
	elif pose_scale == 1 and $"sprite".scale.x < 0:
		$"sprite".scale.x *= -1
		$"area".scale.x *= -1

func _check_bounds():
	printt("_check_bounds", terrain)
	#printt("checking bouds for pos ", get_position(), terrain.is_solid(get_position()))
	if !scale_on_map:
		return
	if !Engine.is_editor_hint():
		return
	if !terrain:
		return
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

func _notification(what):
	if !is_inside_tree() || !Engine.is_editor_hint():
		return
	if what == CanvasItem.NOTIFICATION_TRANSFORM_CHANGED:
		call_deferred("_editor_transform_changed")

func _editor_transform_changed():
	_update_terrain()
	_check_bounds()

func hint_request():
	if !get_active():
		return
	if !vm.can_interact():
		return

	if ui_anim == null:
		return

	if ui_anim.is_playing():
		return

	ui_anim.play("hint")

func setup_ui_anim():
	if has_node("ui_anims"):
		ui_anim = get_node("ui_anims")

		for bg in get_tree().get_nodes_in_group("background"):
			bg.connect("right_click_on_bg", self, "hint_request")

	var conn_err = vm.connect("global_changed", self, "global_changed")
	if conn_err:
		vm.report_errors("npc", ["global_changed -> global_changed error: " + String(conn_err)])

func set_light_on_map(p_light):
	light_on_map = p_light
	if light_on_map:
		_update_terrain()
	else:
		modulate(Color(1, 1, 1, 1))

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
	set_position(pos)
	walk_path = []

	if orig_speed:
		speed = orig_speed
		orig_speed = null

	# Walking is not a state, but we must re-set our previous state to reset the animation
	set_state(state)

	if task == "walk":
		if "idles" in animations:
			pose_scale = animations.idles[last_dir + 1]
	_update_terrain(true)

	task = null

	if walk_context != null:
		vm.finished(walk_context)
		walk_context = null

func walk_to(pos, context = null):
	walk_path = terrain.get_terrain_path(get_position(), pos)
	walk_context = context
	if walk_path.size() == 0:
		walk_stop(get_position())
		set_process(false)
		task = null
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

func modulate(color):
	for s in sprites:
		s.set_modulate(color)

func _physics_process(dt):
	last_lmb_dt += dt

	if waiting_dblclick and last_lmb_dt > vm.DOUBLECLICK_TIMEOUT:
		emit_signal("left_click_on_npc", self, waiting_dblclick[0], waiting_dblclick[1])
		last_lmb_dt = 0
		waiting_dblclick = null

func _process(time):
	if task == "walk" or task == "slide":
		var to_walk = speed * last_scale.x * time
		var pos = get_position()
		var old_pos = pos
		if walk_path.size() > 0:
			while to_walk > 0:
				var next
				if walk_path.size() > 1:
					next = walk_path[path_ofs + 1]
				else:
					next = walk_path[path_ofs]

				var dist = pos.distance_to(next)

				if dist > to_walk:
					var n = (next - pos).normalized()
					pos = pos + n * to_walk
					break
				pos = next
				to_walk -= dist
				path_ofs += 1
				if path_ofs >= walk_path.size() - 1:
					walk_stop(walk_destination)
					set_process(false)
					return

		var angle = (old_pos.angle_to_point(pos)) * -1

		set_position(pos)

		if task == "walk":
			last_deg = vm._get_deg_from_rad(angle)
			last_dir = vm._get_dir_deg(last_deg, animations)

			if animation:
				if animation.get_current_animation() != animations.directions[last_dir]:
					animation.play(animations.directions[last_dir])
				pose_scale = animations.directions[last_dir+1]

		# If a z-indexed npc is moved, forcibly update its z index
		_update_terrain(true)

func turn_to(deg):
	if deg < 0 or deg > 360:
		vm.report_errors("interactive", ["Invalid degree to turn to " + str(deg)])

	moved = true

	last_deg = deg
	last_dir = vm._get_dir_deg(deg, animations)

	if animation and animations and "directions" in animations:
		if !animation.get_current_animation() or animation.get_current_animation() != animations.directions[last_dir]:
			# XXX: This requires manually scripting a wait
			# and setting the correct idle animation
			animation.play(animations.directions[last_dir])
		pose_scale = animations.directions[last_dir + 1]
		_update_terrain()

func set_angle(deg):
	if deg < 0 or deg > 360:
		# Compensate for savegame files during a broken version of Escoria
		if vm.loading_game:
			vm.report_warnings("interactive", ["Reset invalid degree " + str(deg)])
			deg = 0
		else:
			vm.report_errors("interactive", ["Invalid degree to turn to " + str(deg)])

	moved = true

	last_deg = deg
	last_dir = vm._get_dir_deg(deg, animations)

	if animation and animations and "idles" in animations:
		pose_scale = animations.idles[last_dir + 1]
		_update_terrain()

func _find_sprites(p = null):
	if p is CanvasItem:
		sprites.push_back(p)
	for i in range(0, p.get_child_count()):
		_find_sprites(p.get_child(i))

func _ready():
	add_to_group("npc")
	add_to_group("highlight_tooltip")

	if has_node("../terrain"):
		terrain = $"../terrain"
		terrain_is_scalenodes = terrain is preload("terrain_scalenodes.gd")

	if interact_position:
		interact_pos = get_node(interact_position)
	elif has_node("interact_pos"):
		interact_pos = $"interact_pos"

	if has_node("camera_pos"):
		camera_pos = $"camera_pos"

	_find_sprites(self)

	# Initialize Node2D items' terrain status like z-index.
	# Stationary items will be set up correctly and
	# if an npc moves, it will handle this in its _process() loop
	_update_terrain(true)

	if Engine.is_editor_hint():
		return

	vm = $"/root/vm"

	var conn_err

	# {{{ Check for interaction area and connect signals only if the npc is interactive
	area = get_node("area")

	conn_err = area.connect("input_event", self, "area_input")
	if conn_err:
		vm.report_errors("npc", ["area.input_event -> area_input error: " + String(conn_err)])

	conn_err = area.connect("mouse_entered", self, "mouse_enter")
	if conn_err:
		vm.report_errors("npc", ["mouse_entered -> mouse_enter error: " + String(conn_err)])

	conn_err = area.connect("mouse_exited", self, "mouse_exit")
	if conn_err:
		vm.report_errors("npc", ["mouse_exited -> mouse_exit error: " + String(conn_err)])

	conn_err = connect("left_click_on_npc", $"/root/scene/game", "ev_left_click_on_npc")
	if conn_err:
		vm.report_errors("npc", ["left_click_on_npc -> ev_left_click_on_npc error: " + String(conn_err)])

	conn_err = connect("left_dblclick_on_npc", $"/root/scene/game", "ev_left_dblclick_on_npc")
	if conn_err:
		vm.report_errors("npc", ["left_dblclick_on_npc -> ev_left_dblclick_on_npc error: " + String(conn_err)])

	conn_err = connect("right_click_on_npc", $"/root/scene/game", "ev_right_click_on_npc")
	if conn_err:
		vm.report_errors("npc", ["right_click_on_npc -> ev_right_click_on_npc error: " + String(conn_err)])

	conn_err = connect("mouse_enter_npc", $"/root/scene/game", "ev_mouse_enter_npc")
	if conn_err:
		vm.report_errors("npc", ["mouse_enter_npc -> ev_mouse_enter_npc error: " + String(conn_err)])

	conn_err = connect("mouse_exit_npc", $"/root/scene/game", "ev_mouse_exit_npc")
	if conn_err:
		vm.report_errors("npc", ["mouse_exit_npc -> ev_mouse_exit_npc error: " + String(conn_err)])
	# }}}

	if events_path != "":
		event_table = vm.compile(events_path)

	# Forbit pipe because it's used to separate flags from actions, like in `:use item | TK`. And space for good measure.
	for c in ["|", " "]:
		if c in global_id:
			vm.report_errors("npc", ["Forbidden character '" + c + "' in global_id: " + global_id])

	if not has_node("sprite"):
		vm.report_errors("npc", ["No sprite node set"])

	if not has_node("collision"):
		vm.report_errors("npc", ["No collision node set"])

	if has_node("animation"):
		animation = $"animation"
		conn_err = animation.connect("animation_finished", self, "anim_finished")
		if conn_err:
			vm.report_errors("npc", ["animation_finished -> anim_finished error: " + String(conn_err)])

	if has_node("audio"):
		audio = $"audio"
		audio.set_bus("SFX")

	_check_focus(false, false)

	vm.register_object(global_id, self)


