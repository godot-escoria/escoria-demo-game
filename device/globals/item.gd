extends "res://globals/interactive.gd"

export var tooltip = ""
export var action = ""
export(String, FILE, ".esc") var events_path = ""
export var global_id = ""
export var use_combine = false
export var inventory = false
export var use_action_menu = true
export(int, -1, 360) var interact_angle = -1
export(NodePath) var interact_position = null
export(Color) var dialog_color = null
export var talk_animation = "talk"
export var active = true setget set_active,get_active
export var placeholders = {}
export var dynamic_z_index = true

var anim_notify = null
var anim_scale_override = null

var ui_anim = null

var event_table = {}

var clicked = false

var interact_pos

func is_clicked():
	return clicked

func get_interact_pos():
	if interact_pos:
		return interact_pos.get_global_position()
	else:
		return get_global_position()

func anim_finished(anim_name):
	# TODO use parameter here?
	if anim_notify != null:
		vm.finished(anim_notify)
		anim_notify = null

	if anim_scale_override != null && self is Node2D:
		set_scale(get_scale() * anim_scale_override)
		anim_scale_override = null

	# Although states are permanent until changed, the underlying animations are not,
	# so we must re-set the state for the appearance of permanence
	set_state(state, true)

	if animations and "idles" in animations:
		pose_scale = animations.idles[last_dir + 1]
		_update_terrain()

func set_active(p_active):
	active = p_active
	if p_active:
		show()
	else:
		hide()

func get_active():
	return active
	#return is_visible()

func run_event(p_ev):
	vm.run_event(p_ev)

func activate(p_action, p_param = null):
	#printt("****** activated ", p_action, p_param, p_action in event_table)
	#print_stack()
	if p_param != null:
		p_action = p_action + " " + p_param.global_id
	if p_action in event_table:
		run_event(event_table[p_action])
	else:
		return false
	return true

func get_action():
	return action
#
func mouse_enter():
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "mouse_enter", self)
	_check_focus(true, false)

func mouse_exit():
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "mouse_exit", self)
	_check_focus(false, false)

func area_input(viewport, event, shape_idx):
	input(event)

func input(event):
	# TODO: Expand this for other input events than mouse
	if event is InputEventMouseButton || event.is_action("ui_accept"):
		if event.is_pressed():
			clicked = true

			var ev_pos = get_global_mouse_position()
			if event.button_index == BUTTON_LEFT:
				get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "clicked", self, ev_pos, event)
			elif event.button_index == BUTTON_RIGHT:
				get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "secondary_click", self, ev_pos, event)
			_check_focus(true, true)
		else:
			clicked = false
#			_check_focus(true, false)

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

func get_tooltip():
	# if `development_lang` matches `text_lang`, don't translate
	if TranslationServer.get_locale() == ProjectSettings.get_setting("escoria/platform/development_lang"):
		if not global_id and ProjectSettings.get_setting("escoria/platform/force_tooltip_global_id"):
			vm.report_errors("item", ["Missing global_id in item with tooltip '" + tooltip + "'"])
		return tooltip

	# Otherwise try to return the translated tooltip
	var tooltip_identifier = global_id + ".tooltip"
	var translated = tr(tooltip_identifier)

	# But if translation isn't found, ensure it can be translated and return placeholder
	if translated == tooltip_identifier:
		if not global_id and ProjectSettings.get_setting("escoria/platform/force_tooltip_global_id"):
			vm.report_errors("item", ["Missing global_id in item with tooltip '" + tooltip + "'"])
		return tooltip_identifier

	return translated

func get_drag_data(point):
	printt("get drag data on point ", point, inventory)
	if !inventory:
		return null

	var c = Control.new()
	var it = duplicate()
	it.set_script(null)
	it.set_position(Vector2(-50, -80))
	c.add_child(it)
	c.show()
	it.show()
	set_drag_preview(c)

	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "background", "force_drag", global_id, c)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "interact", [self, "use"])

	vm.drag_begin(global_id)
	printt("returning for drag data", global_id)
	return global_id

func can_drop_data(point, data):
	return true # always true ?

func drop_data(point, data):
	printt("dropping data ", data, global_id)
	if data == global_id:
		return

	if !inventory:
		return

	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "clicked", self, get_position())
	vm.drag_end()


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

	if p_flip != null && self is Node2D:
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


func set_speaking(p_speaking):
	printt("item set speaking! ", global_id, p_speaking, state)
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

func teleport(obj):
	set_position(obj.global_position)
	moved = true
	_update_terrain(self is Node2D)

func teleport_pos(x, y):
	set_position(Vector2(x, y))
	moved = true
	_update_terrain(self is Node2D)

func _update_terrain(need_z_update=false):
	if dynamic_z_index and need_z_update:
		set_z_index(get_position().y)

	if !scale_on_map && !light_on_map:
		return

	var pos = get_position()
	# Items in the scene tree will issue errors unless this is conditional
	var terrain = $"../terrain" if has_node("../terrain") else null
	if terrain == null:
		return

	var color = terrain.get_terrain(pos)
	var scale_range = terrain.get_scale_range(color.b)

	# The item's - as the player's - `animations` define the direction
	# as 1 or -1. This is stored as `pose_scale` and the easiest way
	# to flip a node is multiply its x-axis scale.
	scale_range.x *= pose_scale

	if self is Node2D and scale_on_map and scale_range != get_scale():
		# Check if `interact_pos` is a child of ours, and if so,
		# take a backup of the global position, because it will be affected by scaling.
		var interact_global_position
		if has_node("interact_pos"):
			interact_global_position = interact_pos.get_global_position()

		self.scale = scale_range

		# If `interact_pos` is a child, it was affected by scaling, so reset it
		# to the expected location.
		if interact_global_position:
			interact_pos.global_position = interact_global_position

	if self is CanvasItem and light_on_map:
		var c = terrain.get_light(pos)
		modulate(c)

func _check_bounds():
	#printt("checking bouds for pos ", get_position(), terrain.is_solid(get_position()))
	if !scale_on_map:
		return
	if !Engine.is_editor_hint():
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
	if what == Node2D.NOTIFICATION_TRANSFORM_CHANGED:
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

	vm.connect("global_changed", self, "global_changed")

func _ready():
	add_to_group("item")

	if Engine.is_editor_hint():
		return

	var area
	if has_node("area"):
		area = get_node("area")
	else:
		area = self

	if ClassDB.class_has_signal(area.get_class(), "input_event"):
		area.connect("input_event", self, "area_input")
	elif ClassDB.class_has_signal(area.get_class(), "gui_input"):
		area.connect("gui_input", self, "input")
	else:
		vm.report_warnings("item", ["No input events possible for global_id " + global_id])

	if ClassDB.class_has_signal(area.get_class(), "mouse_entered"):
		area.connect("mouse_entered", self, "mouse_enter")
		area.connect("mouse_exited", self, "mouse_exit")

	if events_path != "":
		event_table = vm.compile(events_path)

	vm.register_object(global_id, self)

	if animation:
		animation.connect("animation_finished", self, "anim_finished")

	_check_focus(false, false)

	# Initialize Node2D items' terrain status like z-index.
	# Stationary items will be set up correctly and
	# if an item moves, it will handle this in its _process() loop
	call_deferred("_update_terrain", self is Node2D)

	if interact_position:
		interact_pos = get_node(interact_position)
	elif has_node("interact_pos"):
		interact_pos = $"interact_pos"
