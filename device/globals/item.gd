#tool

extends "res://globals/interactive.gd"

export var tooltip = ""
export var action = ""
export(String, FILE, ".esc") var events_path = ""
export var global_id = ""
export var use_combine = false
export var inventory = false
export var use_action_menu = true
export(int, -1, 360) var interact_angle = -1
export(Color) var dialog_color = null
export var talk_animation = "talk"
export var active = true setget set_active,get_active
export var placeholders = {}
export var use_custom_z = false

var anim_notify = null
var anim_scale_override = null

var ui_anim = null

var event_table = {}

var clicked = false

func is_clicked():
	return clicked

#func _set(name, val):
#	if name == "events_path":
#		event_table = vm.compile(val)
#		events_path = val
#		return
#	if name in self:
#		self[name] = val

func get_interact_pos():
	if has_node("interact_pos"):
		return get_node("interact_pos").get_global_position()
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

	var cur = animation.get_current_animation()
	if cur != state:
		set_state(state, true)

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

			if event.button_index == BUTTON_LEFT:
				get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "clicked", self, event.get_global_position(), event)
			elif event.button_index == BUTTON_RIGHT:
				get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "secondary_click", self, event.get_global_position(), event)
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

	if p_notify == null && (!has_node("animation") || !get_node("animation").has_animation(p_anim)):
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
		get_node("animation").play(p_anim, -1, -1, true)
	else:
		get_node("animation").play(p_anim)
	anim_notify = p_notify

	#_debug_states()


func set_speaking(p_speaking):
	printt("item set speaking! ", global_id, p_speaking, state)
	#print_stack()
	if !has_node("animation"):
		return
	if talk_animation == "":
		return
	if p_speaking:
		if get_node("animation").has_animation(talk_animation):
			get_node("animation").play(talk_animation)
			get_node("animation").seek(0, true)
		#else:
		#	set_state(state, true)
	else:
		if get_node("animation").is_playing():
			get_node("animation").stop()
		set_state(state, true)
	pass

func set_state(p_state, p_force = false):
	printt("set state ", "global_id: ", global_id, "state: ", state, "p_state: ", p_state, "p_force: ", p_force)
	#print_stack()
	if state == p_state && !p_force:
		return
	if has_node("animation"):
		get_node("animation").stop()
	state = p_state
	if animation != null:
		printt("has animation", animation.has_animation(p_state))
		if animation.is_playing() && animation.get_current_animation() == p_state:
			return
		if animation.has_animation(p_state):
			printt("playing animation ", p_state)
			animation.play(p_state)
#
#
func teleport(obj):
	set_position(obj.get_global_pos())
	_update_terrain()

func teleport_pos(x, y):
	set_position(Vector2(x, y))
	_update_terrain()

func _update_terrain():
	if self is Node2D && !use_custom_z:
		set_z_index(get_position().y)
	if !scale_on_map && !light_on_map:
		return

	var pos = get_position()
	var terrain = get_node("../terrain")
	if terrain == null:
		return
	var color = terrain.get_terrain(pos)
	var scale_range = terrain.get_scale_range(color.b)

	if scale_on_map && (self is Node2D) && scale_range != get_scale():
		var c = terrain.get_terrain(pos)
		var s = terrain.get_scale_range(c.b)
		set_scale(s)

	if light_on_map:
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
			bg.connect("right_click_on_bg",self,"hint_request")
	vm.connect("global_changed", self, "global_changed")

func set_costume(costume):
	var node = get_node(costume)

	# Any value will default to this if there's a Sprite named sprite
	if !node:
		if has_node("sprite") and $"sprite" is Sprite:
			node = $"sprite"

	# Otherwise assume there's an "animation"
	if !node:
		node = $"animation"

	if node is Sprite:
		node.show()
		for child in get_children():
			if child is Sprite and child != node:
				child.hide()
	else:
		assert(node is AnimationPlayer)
		node.play(animations.idles[last_dir])

func _ready():

	if Engine.is_editor_hint():
		return

	var area
	if has_node("area"):
		area = get_node("area")
	else:
		area = self
	if area is Area2D:
		area.connect("input_event", self, "area_input")
	else:
		area.connect("gui_input", self, "input")

	area.connect("mouse_entered", self, "mouse_enter")
	area.connect("mouse_exited", self, "mouse_exit")

	if events_path != "":
		event_table = vm.compile(events_path)
	if global_id != "":
		vm.register_object(global_id, self)
	if has_node("animation"):
		get_node("animation").connect("animation_finished", self, "anim_finished")

	_check_focus(false, false)

	call_deferred("setup_ui_anim")

	call_deferred("_update_terrain")
