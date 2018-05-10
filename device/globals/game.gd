extends Node

var player
var mode = "default"
var action_menu = null
var inventory
export(String,FILE) var fallbacks_path = ""
export var inventory_enabled = true setget set_inventory_enabled
var fallbacks
var check_joystick = false
var joystick_mode = false
var min_interact_dist = 50*50
var last_obj = null

var current_action = ""
var current_tool = null

var click
var click_anim

var camera
export var camera_limits = Rect2()

var tooltip

func set_mode(p_mode):
	mode = p_mode

func mouse_enter(obj):
	var text
	var tt = obj.get_tooltip()

	# When following the mouse, prevent text from flashing for a moment in the wrong place
	if ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse"):
		var pos = get_viewport().get_mouse_position()
		pos -= tooltip.get_size() / Vector2(2, 1)
		tooltip.set_position(pos)

	# We must hide all non-inventory tooltips and interactions when the inventory is open
	if action_menu and inventory.is_visible():
		if obj.inventory:
			if !current_action:
				text = tr(tt)
			else:
				var action = inventory.get_action()
				if action == "":
					action = current_action
				text = tr(action + ".id")
				text = text.replace("%1", tr(tt))
			get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", text)
			vm.hover_begin(obj)
	else:
		if current_action != "" && current_tool != null:
			text = tr(current_action + ".combine_id")
			text = text.replace("%2", tr(tt))
			text = text.replace("%1", tr(current_tool.get_tooltip()))
		elif obj.inventory:
			if !current_action:
				text = tr(tt)
			else:
				var action = inventory.get_action()
				if action == "":
					action = current_action
				text = tr(action + ".id")
				text = text.replace("%1", tr(tt))
		else:
			text = tt

		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", text)
		vm.hover_begin(obj)

func mouse_exit(obj):
	var text
	#var tt = obj.get_tooltip()
	if current_action != "" && current_tool != null:
		text = tr(current_action + ".id")
		text = text.replace("%1", tr(current_tool.get_tooltip()))
	else:
		text = ""
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", text)

	# Want to retain the hover if the player is about to perform an action
	if !current_action:
		vm.hover_end()

func clear_action():
	current_tool = null
	# It is logical for action menus' actions to be cleared, but verb menus to persist
	if action_menu:
		current_action = ""

func set_current_action(p_act):
	if p_act != current_action:
		set_current_tool(null)
	current_action = p_act


func set_current_tool(p_tool):
	current_tool = p_tool

func can_click():
	# Check certain global state to see if an object could be clicked

	if !vm.can_interact():
		return false

	if !player:
		return false

	if mode != "default":
		return false

	return true

func clicked(obj, pos, input_event = null):
	if not can_click():
		return

	var walk_context = null
	var action = obj.get_action()

	# XXX: Why does this disable joystick_mode?
	joystick_mode = false

	if input_event:
		walk_context = {"fast": input_event.doubleclick}

	# If an background_area is covered by an item, the item "wins"
	if obj is esc_type.BACKGROUND_AREA:
		for area in obj.get_child(0).get_overlapping_areas():
			if area.has_method("is_clicked") and area.is_clicked():
				return

	# Hide the action menu (where available) when performing actions, so it's not eg. open while walking
	if action_menu:
		action_menu.stop()

	if action == "walk":
		if click:
			click.set_position(pos)
		if click_anim:
			click_anim.play("click")

		if inventory and inventory.is_collapsible:
			inventory.close()

		player.walk_to(pos, walk_context)
		# Leave the tooltip if the player is in eg. a "use key with" state
		if !current_action:
			get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", "")

	elif obj.inventory:
		# Use and look are the only valid choices with an action menu
		if action_menu:
			current_action = "use"
			# XXX: Setting an action here does not update the tooltip like `mouse_enter` does. Compensate.
			var text = tr("use.id")
			text = text.replace("%1", tr(obj.get_tooltip()))
			get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", text)

		if current_action == "use" && obj.use_combine && current_tool == null:
			set_current_tool(obj)
		else:
			interact([obj, current_action, current_tool])
	elif action != "":
		player.interact([obj, action, current_tool])
	elif current_action != "":
		# Walking the player to perform current_action is fine only when inventory is closed
		if inventory:
			if !inventory.is_collapsible or (inventory.is_collapsible and !inventory.is_visible()):
				player.interact([obj, current_action, current_tool])
	elif obj is esc_type.ITEM:
		if action_menu and obj.use_action_menu:
			if !ProjectSettings.get_setting("escoria/ui/right_mouse_button_action_menu"):
				spawn_action_menu(obj)
			else:
				if obj.has_node("interact_pos"):
					pos = obj.get_node("interact_pos").get_global_position()
				else:
					pos = obj.get_global_position()
				player.walk_to(pos, walk_context)

func secondary_click(obj, pos, input_event = null):
	if not can_click():
		return

	var action = obj.get_action()

	if action == "walk":
		player.walk_to(pos)
		return

	# Hide the action menu (where available) when performing actions, so it's not eg. open while walking
	if action_menu:
		action_menu.stop()

		if obj.use_action_menu:
			if ProjectSettings.get_setting("escoria/ui/right_mouse_button_action_menu"):
				spawn_action_menu(obj)
				return

	if inventory:
		if obj is esc_type.ITEM and obj.inventory:
			# Do not set `look` as permanent action
			interact([obj, "look"])
			# XXX: Moving the mouse during `:look` will cause the tooltip to disappear
			# so the following is a good-enough-for-now fix for it
			get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", obj.get_tooltip())
			vm.hover_begin(obj)

func spawn_action_menu(obj):
	if action_menu == null:
		return

	if player:
		player.walk_stop(player.position)

	var pos = get_viewport().get_mouse_position()
	var am_pos = action_menu.check_clamp(pos, camera)
	action_menu.set_position(am_pos)
	action_menu.show()
	action_menu.start(obj)
	#obj.grab_focus()

func action_menu_selected(obj, action):
	if action == "use" && obj.get_action() != "":
		action = obj.get_action()
	if player != null:
		player.interact([obj, action])
	else:
		interact([obj, action])
	action_menu.stop()

func interact(p_params):
	if mode == "default":
		var obj = p_params[0]
		clear_action()
		var action = p_params[1]
		if !action:
			action = obj.get_action()

		if p_params.size() > 2:
			clear_action()
			if obj == p_params[2]:
				return
			#inventory.close()
			activate(obj, action, p_params[2])
		else:
			#inventory.close()
			activate(obj, action)
			clear_action()
		return

func activate(obj, action, param = null):
	if !vm.can_interact():
		#printt("******************** vm can't interact during activate")
		#print_stack()
		return

	if !obj.activate(action, param):
		if param != null: # try opposite way
			if param.activate(action, obj):
				return
		fallback(obj, action, param)

func fallback(obj, action, param = null):
	if fallbacks == null:
		return
	var comb = action
	if typeof(param) != typeof(null):
		comb = action + " " + param.global_id
		if comb in fallbacks:
			vm.run_event(fallbacks[comb])
			return
	if action in fallbacks:
		vm.run_event(fallbacks[action])
		return
	vm.report_errors(fallbacks_path, ["Invalid action " + comb + " in fallbacks."])

func scene_input(event):
	if event.is_action("quick_save") && event.is_pressed() && !event.is_echo():
		vm.request_autosave()
	if event is InputEventJoypadMotion:
		if event.axis == 0 || event.axis == 1:
			joystick_mode = true
			check_joystick = true
			set_process(true)

	if event is InputEventMouseButton && !event.is_pressed() && event.button_index == BUTTON_LEFT:
		if vm.drag_object != null:
			vm.drag_end()


	if event.is_action("menu_request") && event.is_pressed() && !event.is_echo():
		# Do not display overlay menu with action menu or inventory, it looks silly and weird
		if action_menu:
			if action_menu.is_visible():
				action_menu.stop()

			# Hide inventory if collapsible
			if inventory and inventory.is_collapsible:
				inventory.close()

		if vm.can_save() && vm.can_interact() && vm.menu_enabled():
			main.load_menu(ProjectSettings.get_setting("escoria/ui/main_menu"))
		else:
			#get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "ui_blocked")
			if vm.menu_enabled():
				main.load_menu(ProjectSettings.get_setting("escoria/ui/in_game_menu"))
			else:
				get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "ui_blocked")


func _process(time):
	if !vm.can_interact():
		check_joystick = false
		return

	if player == null || player == self:
		return
	if joystick_mode:
		var objs = vm.get_registered_objects()
		var mobj = null
		var mdist
		var pos = player.get_position()
		for key in objs:
			if key == "player":
				continue
			if !objs[key].is_type("Control"):
				continue
			if !objs[key].is_visible():
				continue
			if objs[key].tooltip == "":
				continue
			var objpos = objs[key].get_interact_pos()
			var odist = pos.distance_squared_to(objpos)
			if typeof(mobj) == typeof(null):
				mobj = objs[key]
				mdist = odist
			else:
				if odist < mdist:
					mdist = odist
					mobj = objs[key]
		if typeof(mobj) != typeof(null):
			if mdist < min_interact_dist:
				if mobj != last_obj:
					spawn_action_menu(mobj)
					mouse_enter(mobj)
					last_obj = mobj
			else:
				mouse_exit(mobj)
				last_obj = null

	if !check_joystick:
		return

	var dir = Vector2(Input.get_joy_axis(0, 0), Input.get_joy_axis(0, 1));
	if dir.length_squared() < 0.1:
		check_joystick = false
		return

	player.walk_to(player.get_position() + dir * 20)

func _input(ev):
	if ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse"):
		# Must verify `position` is there, key inputs do not have it
		if vm.hover_object and "position" in ev:
			var pos = ev.position - tooltip.get_size() / Vector2(2, 1)
			tooltip.set_position(pos)

func set_inventory_enabled(p_enabled):
	inventory_enabled = p_enabled
	if !has_node("hud_layer/hud/inv_toggle"):
		return
	if inventory_enabled:
		get_node("hud_layer/hud/inv_toggle").show()
	else:
		get_node("hud_layer/hud/inv_toggle").hide()

func set_camera_limits():
	var cam_limit = camera_limits
	if camera_limits.size.x == 0 and camera_limits.size.y == 0:
		var area = Rect2()
		for child in get_parent().get_children():
			if child is esc_type.BACKGROUND:
				var pos = child.get_global_position()
				var size = child.get_size()
				area = area.expand(pos)
				area = area.expand(pos + size)
			if child is esc_type.BACKGROUND_AREA:
				var pos = child.get_global_position()
				var size = child.get_texture().get_size()
				area = area.expand(pos)
				area = area.expand(pos + size)

		camera.limit_left = area.position.x
		camera.limit_right = area.position.x + area.size.x
		camera.limit_top = area.position.y
		camera.limit_bottom = area.position.y + area.size.y

		if area.size.x == 0 or area.size.y == 0:
			printt("No limit area! Using viewport")
			area.size = get_viewport().size

		printt("setting camera limits from scene ", area)
		cam_limit = area
	else:
		camera.limit_left = camera_limits.position.x
		camera.limit_right = camera_limits.position.x + camera_limits.size.x
		camera.limit_top = camera_limits.position.y
		camera.limit_bottom = camera_limits.position.y + camera_limits.size.y + main.screen_ofs.y * 2
		printt("setting camera limits from parameter ", camera_limits)

	camera.set_offset(main.screen_ofs * 2)
	vm.set_cam_limits(cam_limit)

	#vm.update_camera(0.000000001)

func load_hud():
	var hres = vm.res_cache.get_resource(vm.get_hud_scene())
	get_node("hud_layer/hud").replace_by_instance(hres)

	# Add inventory to hud layer, usually hud_minimal.tscn, if found in project settings
	if inventory_enabled:
		if !$hud_layer.has_node("inventory") and ProjectSettings.get_setting("escoria/ui/inventory"):
			inventory = load(ProjectSettings.get_setting("escoria/ui/inventory")).instance()
			if inventory and inventory is esc_type.INVENTORY:
				inventory.hide()
				$hud_layer.add_child(inventory)
		else:
			inventory = get_node("hud_layer/hud/inventory")

	# Add action menu to hud layer if found in project settings
	if ProjectSettings.get_setting("escoria/ui/action_menu"):
		action_menu = load(ProjectSettings.get_setting("escoria/ui/action_menu")).instance()
		if action_menu and action_menu is esc_type.ACTION_MENU:
			$hud_layer.add_child(action_menu)

	#if inventory_enabled:
	#	get_node("hud_layer/hud/inv_toggle").show()
	#else:
	#	get_node("hud_layer/hud/inv_toggle").hide()

	tooltip = get_node("hud_layer/hud/tooltip")

func _ready():
	add_to_group("game")
	player = get_node("../player")

	if fallbacks_path != "":
		fallbacks = vm.compile(fallbacks_path)

	if has_node("click"):
		click = get_node("click")
	if has_node("click_anim"):
		click_anim = get_node("click_anim")

	camera = get_node("camera")

	vm.set_camera(camera)

	call_deferred("set_camera_limits")
	call_deferred("load_hud")

