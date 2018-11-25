extends Node

var player
var mode = "default"
var inventory
export(String,FILE) var fallbacks_path = ""
export var inventory_enabled = true setget set_inventory_enabled
var fallbacks
var check_joystick = false
var joystick_mode = false
var min_interact_dist = 50*50
var last_obj = null

export var drag_margin_left = 0.2
export var drag_margin_top = 0.2
export var drag_margin_right = 0.2
export var drag_margin_bottom = 0.2

var click
var click_anim

var default_obj_action
var obj_action_req_dblc

var camera
export var camera_limits = Rect2()

func set_mode(p_mode):
	mode = p_mode

func tooltip_clamped_position(tt_pos):
	var width = float(ProjectSettings.get("display/window/size/width"))
	var height = float(ProjectSettings.get("display/window/size/height"))
	var tt_size = vm.tooltip.get_size()
	var center_offset = tt_size.x / 2

	# We want to have the center of the tooltip above where the cursor is, compensate first
	tt_pos.x -= center_offset  # Shift it half-way to the left
	tt_pos.y -= tt_size.y  # Shift it one size up

	var dist_from_right = width - (tt_pos.x + tt_size.x)  # Check if the right edge, not eg. center, is overflowing
	var dist_from_left = tt_pos.x
	var dist_from_bottom = height - (tt_pos.y + tt_size.y)
	var dist_from_top = tt_pos.y

	## XXX: Godot has serious issues with the width of the text, so tooltips need
	## to be wide at a fixed size, which makes clamping a bit weird.
	## The code is left here in case someone fixes Godot.
	if dist_from_right < 0:
		tt_pos.x += dist_from_right
	if dist_from_left < 0:
		tt_pos.x -= dist_from_left
	if dist_from_bottom < 0:
		tt_pos.y += dist_from_bottom
	if dist_from_top < 0:
		tt_pos.y -= dist_from_top

	return tt_pos

func can_click():
	# Check certain global state to see if an object could be clicked

	if !vm.can_interact():
		return false

	if !player:
		return false

	if mode != "default":
		return false

	return true

func ev_left_click_on_bg(obj, pos, event):
	printt(obj.name, "left-clicked at", pos, "with", event, can_click())

	if not can_click():
		return

	if vm.action_menu:
		vm.action_menu.stop()

	# If it's possible to click outside the inventory, don't walk but only close it
	if inventory and inventory.blocks_tooltip():
		inventory.close()
		return

	var walk_context = {"fast": event.doubleclick}

	if click:
		click.set_position(pos)
	if click_anim:
		click_anim.play("click")

	player.walk_to(pos, walk_context)
	# Leave the tooltip if the player is in eg. a "use key with" state
	if not vm.current_action and vm.hover_object:
		vm.hover_end()

	vm.maybe_hide_tooltip()

func ev_left_click_on_item(obj, pos, event):
	printt(obj.name, "left-clicked at", pos, "with", event, can_click())

	if not can_click():
		return

	if vm.action_menu and obj.use_action_menu:
		if !ProjectSettings.get_setting("escoria/ui/right_mouse_button_action_menu"):
			spawn_action_menu(obj)
			return
		elif vm.action_menu.is_visible():
			# XXX: Can't close action menu here or doubleclick would cause an action
			if obj == vm.hover_object:
				return
			else:
				vm.action_menu.stop()

	if inventory and inventory.blocks_tooltip():
		inventory.close()
		return

	var obj_action = obj.get_action()
	var action = "walk"

	# Start off by checking a non-doubleclick default action
	if not obj_action_req_dblc:
		if obj_action:
			action = obj_action
		elif default_obj_action:
			action = default_obj_action

	var walk_context = {"fast": event.doubleclick}

	if click:
		click.set_position(pos)
	if click_anim:
		click_anim.play("click")

	if obj.has_method("get_interact_pos"):
		pos = obj.get_interact_pos()

	player.walk_to(pos, walk_context)

	# XXX: Interacting with current_tool etc should be a signal
	if action != "walk" or vm.current_action:
		if inventory and not inventory.blocks_tooltip():
			player.interact([obj, vm.current_action, vm.current_tool])

func ev_left_dblclick_on_item(obj, pos, event):
	printt(obj.name, "left-dblclicked at", pos, "with", event, can_click())

	if not can_click():
		return

	if vm.action_menu and vm.action_menu.is_visible():
		vm.action_menu.stop()
		return

	var obj_action = obj.get_action()
	var action = "walk"

	# See if there's a doubleclick default action
	if obj_action_req_dblc:
		if obj_action:
			action = obj_action
		elif default_obj_action:
			action = default_obj_action

	if click:
		click.set_position(pos)
	if click_anim:
		click_anim.play("click")

	var walk_context = {"fast": event.doubleclick}
	player.walk_to(pos, walk_context)
	if action != "walk":
		player.interact([obj, action, vm.current_tool])

func ev_right_click_on_item(obj, pos, event):
	printt(obj.name, "right-clicked at", pos, "with", event, can_click())

	if not can_click():
		return

	var inventory_open = inventory and inventory.blocks_tooltip()

	if obj.use_action_menu and not inventory_open:
		if ProjectSettings.get_setting("escoria/ui/right_mouse_button_action_menu"):
			spawn_action_menu(obj)
			return
	elif inventory_open:
		inventory.close()

func ev_left_click_on_inventory_item(obj, pos, event):
	printt(obj.name, "left-clicked at", pos, "with", event, can_click())

	if not can_click():
		return

	# Use and look are the only valid choices with an action menu
	if vm.action_menu:
		vm.set_current_action("use")
		# XXX: Setting an action here does not update the tooltip like `mouse_enter` does. Compensate.
		var text = tr("use.id")
		text = text.replace("%1", tr(obj.get_tooltip()))
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", text)

	if vm.current_action == "use" and obj.use_combine:
		if not vm.current_tool:
			vm.set_current_tool(obj)
		elif vm.current_tool != obj:
			interact([obj, vm.current_action, vm.current_tool])

func ev_right_click_on_inventory_item(obj, pos, event):
	printt(obj.name, "right-clicked at", pos, "with", event, can_click())

	if not can_click():
		return

	# Do not set `look` as permanent action
	interact([obj, "look"])
	# XXX: Moving the mouse during `:look` will cause the tooltip to disappear
	# so the following is a good-enough-for-now fix for it
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", obj.get_tooltip())
	vm.hover_begin(obj)

func ev_mouse_enter_item(obj):
	assert not obj.inventory
	printt(obj.name, "mouse_enter_item")

	## XXX: Would want a design where this is not relevant!
	if vm.overlapped_obj and vm.overlapped_obj != obj:
		# Be sure we have exited the other object, because
		# sometimes item2's `mouse_entered` happens before
		# item1's `mouse_exited`. This causes the tooltip to disappear!
		yield(vm.overlapped_obj, "mouse_exit_item")

	vm.set_overlapped_obj(obj)

	# Immediately bail out if the action menu is open
	if vm.action_menu and vm.action_menu.is_visible():
		assert(!vm.tooltip.visible)
		return

	# Also bail out if inventory blocks us
	if inventory and inventory.blocks_tooltip():
		return

	if vm.tooltip:
		var tt = obj.get_tooltip()
		var text

		# XXX: The warning report may be removed if it turns out to be too annoying in practice
		if not tt:
			vm.report_warnings("game", ["No tooltip for item " + obj.name])
			# For a passive item, it's fine to set an empty tooltip, but if we have a passive and
			# an active esc_type.ITEM overlapping, say a window and a light that will move later,
			# the tooltip may be emptied by the light not having a tooltip. This is because the
			# `mouse_enter` events have no guaranteed order.
			return

		# {{{ tooltip handling
		if vm.current_action and vm.current_tool:
			text = tr(vm.current_action + ".combine_id")
			text = text.replace("%2", tr(tt))
			text = text.replace("%1", tr(vm.current_tool.get_tooltip()))
		else:
			text = tr(tt)
		# }}}

		# When following the mouse, prevent text from flashing for a moment in the wrong place
		if ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse"):
			var pos = get_viewport().get_mouse_position()

			pos = tooltip_clamped_position(pos)

			vm.tooltip.set_position(pos)

		# XXX: Usually doesn't end up overflowing the stack as a regular call, but it has happened
		#      so try to guard against it
		get_tree().call_group_flags(SceneTree.GROUP_CALL_UNIQUE, "hud", "set_tooltip", text)

	vm.hover_begin(obj)

func ev_mouse_enter_inventory_item(obj):
	assert obj.inventory
	printt(obj.name, "mouse_enter_inventory_item")

	assert inventory

	if vm.tooltip:
		var tt = obj.get_tooltip()
		var text

		# XXX: The warning report may be removed if it turns out to be too annoying in practice
		if not tt:
			vm.report_warnings("game", ["No tooltip for item " + obj.name])
			# For a passive item, it's fine to set an empty tooltip, but if we have a passive and
			# an active esc_type.ITEM overlapping, say a window and a light that will move later,
			# the tooltip may be emptied by the light not having a tooltip. This is because the
			# `mouse_enter` events have no guaranteed order.
			return

		# {{{ tooltip handling
		if inventory.blocks_tooltip():
			if not vm.current_action:
				text = tr(tt)
			else:
				var action = inventory.get_action()
				if action == "":
					action = vm.current_action

				if vm.current_tool and vm.current_tool != obj:
					text = tr(vm.current_action + ".combine_id")
					text = text.replace("%2", tr(tt))
					text = text.replace("%1", tr(vm.current_tool.get_tooltip()))
				elif vm.current_tool:
					text = tr(action + ".id")
					text = text.replace("%1", tr(tt))

			get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", text)

			vm.hover_begin(obj)
		else:
			if not vm.current_action:
				text = tr(tt)
			else:
				var action = inventory.get_action()
				if action == "":
					action = vm.current_action
				text = tr(action + ".id")
				text = text.replace("%1", tr(tt))
		# }}}

		# When following the mouse, prevent text from flashing for a moment in the wrong place
		if ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse"):
			var pos = get_viewport().get_mouse_position()

			pos = tooltip_clamped_position(pos)

			vm.tooltip.set_position(pos)

		get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "hud", "set_tooltip", text)

	vm.hover_begin(obj)

func ev_mouse_exit_item(obj):
	printt(obj.name, "mouse_exit_item")

	if vm.tooltip:
		var text = ""

		if vm.current_action and vm.current_tool:
			text = tr(vm.current_action + ".id")
			text = text.replace("%1", tr(vm.current_tool.get_tooltip()))

		get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "hud", "set_tooltip", text)

	# Want to retain the hover if the player is about to perform an action
	if not vm.current_action and vm.hover_object:
		vm.hover_end()

	vm.clear_overlapped_obj()

func ev_mouse_exit_inventory_item(obj):
	printt(obj.name, "mouse_exit_inventory_item")

	# If we don't return here, and the cursor is moved around over
	# items with the action menu open, we would get an empty tooltip
	# when the action menu closes
	if vm.action_menu and vm.action_menu.is_visible():
		assert(!vm.tooltip.visible)
		return

	if vm.tooltip:
		var text = ""

		if vm.current_action and vm.current_tool:
			text = tr(vm.current_action + ".id")
			text = text.replace("%1", tr(vm.current_tool.get_tooltip()))

		get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "hud", "set_tooltip", text)

	# Want to retain the hover if the player is about to perform an action
	if not vm.current_action and vm.hover_object:
		vm.hover_end()

func ev_mouse_enter_trigger(obj):
	printt(obj.name, "mouse_enter_trigger")

	# Immediately bail out if the action menu is open
	if vm.action_menu and vm.action_menu.is_visible():
		assert(!vm.tooltip.visible)
		return

	# Also bail out if inventory blocks us
	if inventory and inventory.blocks_tooltip():
		return

	if vm.tooltip:
		var tt = obj.get_tooltip()
		var text

		# XXX: The warning report may be removed if it turns out to be too annoying in practice
		if not tt:
			vm.report_warnings("game", ["No tooltip for trigger " + obj.name])
			# For a passive item, it's fine to set an empty tooltip, but if we have a passive and
			# an active esc_type.ITEM overlapping, say a window and a light that will move later,
			# the tooltip may be emptied by the light not having a tooltip. This is because the
			# `mouse_enter` events have no guaranteed order.
			return

		text = tr(tt)

		# When following the mouse, prevent text from flashing for a moment in the wrong place
		if ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse"):
			var pos = get_viewport().get_mouse_position()

			pos = tooltip_clamped_position(pos)

			vm.tooltip.set_position(pos)

		get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "hud", "set_tooltip", text)

	vm.hover_begin(obj)

func ev_mouse_exit_trigger(obj):
	printt(obj.name, "mouse_exit_trigger")

	if vm.tooltip:
		var text = ""

		if vm.current_action and vm.current_tool:
			text = tr(vm.current_action + ".id")
			text = text.replace("%1", tr(vm.current_tool.get_tooltip()))

		get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "hud", "set_tooltip", text)

	vm.clear_overlapped_obj()

func spawn_action_menu(obj):
	if vm.action_menu == null:
		return

	if player:
		player.walk_stop(player.position)

	var pos = get_viewport().get_mouse_position()
	var am_pos = vm.action_menu.clamped_position(pos)
	vm.action_menu.set_position(am_pos)
	vm.action_menu.show()
	vm.action_menu.start(obj)

func action_menu_selected(obj, action):
	if action == "use" && obj.get_action() != "":
		action = obj.get_action()
	if player != null:
		player.interact([obj, action])
	else:
		interact([obj, action])
	vm.action_menu.stop()

func interact(p_params):
	if mode == "default":
		var obj = p_params[0]
		vm.clear_action()
		var action = p_params[1]
		if !action:
			action = obj.get_action()

		if p_params.size() > 2:
			vm.clear_action()
			if obj == p_params[2]:
				return
			#inventory.close()
			activate(obj, action, p_params[2])
		else:
			#inventory.close()
			activate(obj, action)
			vm.clear_action()
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
		if player:
			# Resolve the angle to look toward and call `walk_stop` to make magic happen
			player.resolve_angle_to(obj)
			player.walk_stop(player.position)

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

	if event.is_action("menu_request") && event.is_pressed() && !event.is_echo():
		handle_menu_request()

func handle_menu_request():
	var menu_enabled = vm.menu_enabled()
	if vm.can_save() and vm.can_interact() and menu_enabled:
		# Do not display overlay menu with action menu or inventory, it looks silly and weird
		if vm.action_menu:
			if vm.action_menu.is_visible():
				vm.action_menu.stop()

		# Forcibly close inventory without animation if collapsible and visible
		if inventory and inventory.blocks_tooltip():
			inventory.force_close()

		# Finally show the menu
		main.load_menu(ProjectSettings.get_setting("escoria/ui/in_game_menu"))
	elif not menu_enabled:
		get_tree().call_group("game", "ui_blocked")

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
			var pos = tooltip_clamped_position(ev.position)
			vm.tooltip.set_global_position(pos)

func set_inventory_enabled(p_enabled):
	inventory_enabled = p_enabled
	if !has_node("hud_layer/hud/inv_toggle"):
		return
	if inventory_enabled:
		$"hud_layer/hud/inv_toggle".show()
	else:
		$"hud_layer/hud/inv_toggle".hide()

func set_camera_limits():
	var cam_limit = camera_limits
	if camera_limits.size.x == 0 and camera_limits.size.y == 0:
		var area = Rect2()
		for child in get_parent().get_children():
			if child is esc_type.BACKGROUND:
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
	$"hud_layer/hud".replace_by_instance(hres)

	var hud = $"hud_layer/hud"

	if hud.has_node("tooltip"):
		var tooltip = hud.get_node("tooltip")
		vm.register_tooltip(tooltip)

	# Add inventory to hud layer, usually hud_minimal.tscn, if found in project settings
	# and not present in the `game` scene's hud.
	if inventory_enabled:
		if hud.has_node("inventory"):
			inventory = hud.get_node("inventory")
			printt("Found inventory in hud", hud)
		else:
			var inventory_scene = ProjectSettings.get_setting("escoria/ui/inventory")
			if inventory_scene:
				inventory = load(inventory_scene).instance()
				if inventory and inventory is esc_type.INVENTORY:
					if inventory.is_collapsible:
						inventory.hide()
					hud.add_child(inventory)
					hud.move_child(inventory, 0)
					printt("Added inventory to hud", hud)

	if has_node("hud_layer/hud/inv_toggle"):
		if inventory_enabled:
			$"hud_layer/hud/inv_toggle".show()
		else:
			$"hud_layer/hud/inv_toggle".hide()

	# Add action menu to hud layer if found in project settings
	if ProjectSettings.get_setting("escoria/ui/action_menu"):
		var action_menu = load(ProjectSettings.get_setting("escoria/ui/action_menu")).instance()
		if action_menu:
			$"hud_layer".add_child(action_menu)

func _ready():
	add_to_group("game")
	if has_node("../player"):
		player = $"../player"

	if fallbacks_path != "":
		fallbacks = vm.compile(fallbacks_path)

	if has_node("click"):
		click = get_node("click")
	if has_node("click_anim"):
		click_anim = get_node("click_anim")

	default_obj_action = ProjectSettings.get_setting("escoria/platform/default_object_action")
	obj_action_req_dblc = ProjectSettings.get_setting("escoria/platform/object_action_requires_doubleclick")

	camera = get_node("camera")

	camera.drag_margin_left = drag_margin_left
	camera.drag_margin_top = drag_margin_top
	camera.drag_margin_right = drag_margin_right
	camera.drag_margin_bottom = drag_margin_bottom

	vm.set_camera(camera)

	call_deferred("set_camera_limits")
	call_deferred("load_hud")

