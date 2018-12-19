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

	# Make it possible to abort an interaction before the player interacts
	if player.interact_status == player.INTERACT_WALKING:
		# by overriding the interaction status
		player.interact_status = player.INTERACT_NONE
		player.params_queue = null
		player.walk_to(pos, walk_context)
		return

	if click:
		click.set_position(pos)
	if click_anim:
		click_anim.play("click")

	player.walk_to(pos, walk_context)

	if vm.tooltip:
		if not vm.current_tool:
			vm.tooltip.hide()

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

	var walk_context = {"fast": event.doubleclick}

	# Make it possible to abort an interaction before the player interacts
	if player.interact_status == player.INTERACT_WALKING:
		# by overriding the interaction status
		player.interact_status = player.INTERACT_NONE
		player.params_queue = null
		player.walk_to(pos, walk_context)
		return

	var obj_action = obj.get_action()
	var action = "walk"

	# Start off by checking a non-doubleclick default action
	if not obj_action_req_dblc:
		if obj_action:
			action = obj_action
		elif default_obj_action:
			action = default_obj_action

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

	var walk_context = {"fast": event.doubleclick}

	# Make it possible to abort an interaction before the player interacts
	if player.interact_status == player.INTERACT_WALKING:
		# by overriding the interaction status
		player.interact_status = player.INTERACT_NONE
		player.params_queue = null
		player.walk_to(pos, walk_context)

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

	if action != "walk":
		# Resolve telekinesis
		if action in obj.event_table:
			var telekinetic = "TK" in obj.event_table[action]["ev_flags"]
			if player.task == "walk":
				player.walk_stop(player.get_position())
				vm.clear_current_action()

		player.interact([obj, action, vm.current_tool])
	else:
		player.walk_to(pos, walk_context)

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

	if vm.current_action == "use" and obj.use_combine:
		if not vm.current_tool:
			vm.set_current_tool(obj)
		elif vm.current_tool != obj:
			interact([obj, vm.current_action, vm.current_tool])

	if vm.tooltip:
		vm.tooltip.update()

func ev_right_click_on_inventory_item(obj, pos, event):
	printt(obj.name, "right-clicked at", pos, "with", event, can_click())

	if not can_click():
		return

	if vm.current_tool:
		vm.clear_current_tool()
		if vm.tooltip:
			vm.tooltip.update()
	else:
		# Do not set `look` as permanent action
		interact([obj, "look"])
		# XXX: Moving the mouse during `:look` will cause the tooltip to disappear
		# so the following is a good-enough-for-now fix for it
		if vm.tooltip:
			vm.tooltip.update()

func ev_mouse_enter_item(obj):
	if obj.inventory:
		vm.report_errors("game", ["Mouse entered inventory non-inventory item: " + obj.global_id])

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
		if vm.tooltip and vm.tooltip.visible:
			vm.report_errors("game", ["Tooltip visible while action menu is visible"])
		return

	# Also bail out if inventory blocks us
	if inventory and inventory.blocks_tooltip():
		return

	if vm.tooltip:
		var tt = obj.get_tooltip()

		# XXX: The warning report may be removed if it turns out to be too annoying in practice
		if not tt:
			vm.report_warnings("game", ["No tooltip for item " + obj.name])
			# For a passive item, it's fine to set an empty tooltip, but if we have a passive and
			# an active esc_type.ITEM overlapping, say a window and a light that will move later,
			# the tooltip may be emptied by the light not having a tooltip. This is because the
			# `mouse_enter` events have no guaranteed order.
			return

	vm.hover_begin(obj)

func ev_mouse_enter_inventory_item(obj):
	if not inventory:
		vm.report_errors("game", ["Mouse entered inventory item without inventory: " + obj.global_id])
	if not obj.inventory:
		vm.report_errors("game", ["Mouse entered non-inventory inventory item: " + obj.global_id])

	printt(obj.name, "mouse_enter_inventory_item")

	if vm.tooltip:
		var tt = obj.get_tooltip()

		# XXX: The warning report may be removed if it turns out to be too annoying in practice
		if not tt:
			vm.report_warnings("game", ["No tooltip for item " + obj.name])
			# For a passive item, it's fine to set an empty tooltip, but if we have a passive and
			# an active esc_type.ITEM overlapping, say a window and a light that will move later,
			# the tooltip may be emptied by the light not having a tooltip. This is because the
			# `mouse_enter` events have no guaranteed order.
			return

	vm.hover_begin(obj)

func ev_mouse_exit_item(obj):
	printt(obj.name, "mouse_exit_item")

	vm.clear_overlapped_obj()

	if vm.action_menu and vm.action_menu.is_visible():
		return

	# Also bail out if inventory blocks us
	if inventory and inventory.blocks_tooltip():
		return

	vm.hover_end()

func ev_mouse_exit_inventory_item(obj):
	printt(obj.name, "mouse_exit_inventory_item")

	# If we don't return here, and the cursor is moved around over
	# items with the action menu open, we would get an empty tooltip
	# when the action menu closes
	if vm.action_menu and vm.action_menu.is_visible():
		if vm.tooltip and vm.tooltip.visible:
			vm.report_errors("game", ["Tooltip visible while action menu is visible"])
		return

	vm.hover_end()

func ev_mouse_enter_trigger(obj):
	printt(obj.name, "mouse_enter_trigger")

	# Immediately bail out if the action menu is open
	if vm.action_menu and vm.action_menu.is_visible():
		if vm.tooltip and vm.tooltip.visible:
			vm.report_errors("game", ["Tooltip visible while action menu is visible"])
		return

	# Also bail out if inventory blocks us
	if inventory and inventory.blocks_tooltip():
		return

	vm.set_overlapped_obj(obj)

	if vm.tooltip:
		var tt = obj.get_tooltip()

		# XXX: The warning report may be removed if it turns out to be too annoying in practice
		if not tt:
			vm.report_warnings("game", ["No tooltip for trigger " + obj.name])
			# For a passive item, it's fine to set an empty tooltip, but if we have a passive and
			# an active esc_type.ITEM overlapping, say a window and a light that will move later,
			# the tooltip may be emptied by the light not having a tooltip. This is because the
			# `mouse_enter` events have no guaranteed order.
			return

	vm.hover_begin(obj)

func ev_mouse_exit_trigger(obj):
	printt(obj.name, "mouse_exit_trigger")

	vm.clear_overlapped_obj()
	# FIXME: Action menu on item, click trigger which causes dialog, hover_object is not set, but should be
	if vm.hover_object:
		vm.hover_end()

func spawn_action_menu(obj):
	if vm.action_menu == null:
		return

	if vm.tooltip and (vm.current_tool or vm.current_action):
		vm.tooltip.hide()
		vm.clear_current_tool()
		vm.clear_current_action()

	if player:
		player.walk_stop(player.position)

	var pos = get_viewport().get_mouse_position()
	vm.action_menu.set_position(pos)
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

func set_inventory_enabled(p_enabled):
	inventory_enabled = p_enabled
	if !has_node("hud_layer/hud/inv_toggle"):
		return
	if inventory_enabled:
		$"hud_layer/hud/inv_toggle".show()
	else:
		$"hud_layer/hud/inv_toggle".hide()

func set_camera_limits():
	var limits = {}
	if camera_limits.size.x == 0 and camera_limits.size.y == 0:
		var area = Rect2()
		for child in get_parent().get_children():
			if child is esc_type.BACKGROUND:
				var pos = child.get_global_position()
				var size = child.get_texture().get_size()
				area = area.expand(pos)
				area = area.expand(pos + size)

		if area.size.x == 0 or area.size.y == 0:
			printt("No limit area! Using viewport")
			area.size = get_viewport().size


		printt("setting camera limits from scene ", area)
		limits = {
			"limit_left": area.position.x,
			"limit_right": area.position.x + area.size.x,
			"limit_top": area.position.y,
			"limit_bottom": area.position.y + area.size.y,
			"set_default": true,
		}
	else:
		limits = {
			"limit_left": camera_limits.position.x,
			"limit_right": camera_limits.position.x + camera_limits.size.x,
			"limit_top": camera_limits.position.y,
			"limit_bottom": camera_limits.position.y + camera_limits.size.y + main.screen_ofs.y * 2,
			"set_default": true,
		}
		printt("setting camera limits from parameter ", camera_limits)

	camera.set_limits(limits)
	camera.set_offset(main.screen_ofs * 2)

	#vm.update_camera(0.000000001)

func load_hud():
	var hres = vm.res_cache.get_resource(vm.get_hud_scene())
	$"hud_layer/hud".replace_by_instance(hres)

	var hud = $"hud_layer/hud"

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

