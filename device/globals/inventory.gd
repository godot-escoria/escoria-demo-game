extends Control

export(bool) var is_collapsible = false

var item_list = []
var page = 0

var page_max
var page_size
var current_action = ""

func blocks_tooltip():
	return self.is_collapsible and self.is_visible()

func change_page(dir):
	page += dir
	if page < 0:
		page = 0
	if page > page_max:
		page = page_max
	sort_items()

func open():
	if is_visible():
		return

	if vm.tooltip:
		# Anything left underneath the inventory is not considered hovering
		if vm.hover_object:
			vm.hover_end()

		vm.tooltip.update()

	if vm.action_menu:
		# `false` is for show_tooltip=false
		vm.action_menu.stop(false)

	sort_items()

	show()

	print("inventory open")

	if has_node("animation"):
		get_node("animation").play("show")


func close():
	if !is_visible():
		return

	if vm.tooltip:
		# We want to hide the tooltip from a collapsible inventory, but not if
		# an item has been selected as `current_tool`.
		if not vm.current_tool:
			vm.tooltip.hide()
		# But if we are closing while hovering ...
		elif vm.hover_object:
			# ... an inventory item ...
			if vm.hover_object is esc_type.ITEM and vm.hover_object.inventory:
				# ... we must exit it to sort out the tooltip
				vm.hover_object.emit_signal("mouse_exit_inventory_item", vm.hover_object)

	var closing_animation = false
	if has_node("animation"):
		if $"animation".is_playing():
			return
		$"animation".play("hide")
		closing_animation = true

	# XXX: What is this `look` node? A verb menu thing?
	if has_node("look"):
		get_node("look").set_pressed(false)

	current_action = ""
	hide()
	print("inventory close")

	# Reset immediately only when there isn't an animation, otherwise let the handler do it
	if not closing_animation:
		vm.reset_overlapped_obj()

func force_close():
	if !is_visible():
		return

	if vm.tooltip:
		vm.tooltip.hide()
	hide()
	printt("inventory force_close")


func toggle():
	if is_visible():
		close()
	else:
		open()

func anim_finished(name):
	if name == "hide":
		hide()
		vm.reset_overlapped_obj()

func sort_items():
	var items = get_node("items")
	var slots = get_node("slots")
	var count = 0
	var focus = false
	for i in range(0, items.get_child_count()):
		var c = items.get_child(i)
		if !vm.inventory_has(c.global_id):
			c.hide()
			continue
		if count >= page_size * (page+1):
			#printt("past page", count, page_size, page)
			c.hide()
		elif count >= page_size * page:
			var slot = count - page_size * page
			c.show()
			printt("showing item", c.global_id, slots.get_child(slot).get_global_position())
			#printt("no focus")
			c.set_global_position(slots.get_child(slot).get_global_position())
			#c.set_focus_mode(Control.FOCUS_NONE)
			if !focus:
				#c.grab_focus()
				focus = true
		else:
			c.hide()
		count += 1
	page_max = int(count / page_size)

	if count > 0 && page > page_max:
		page -= 1
		sort_items()

func inventory_changed():
	printt("** inventory changed")
	if is_visible():
		printt("sorting")
		sort_items()

func global_changed(name):
	if name.find("i/") != 0:
		return
	inventory_changed()

func input(event):
	if event.type == InputEvent.MOUSE_BUTTON && event.pressed:
		toggle()

func get_action():
	return current_action

func look_toggled(pressed):
	if pressed:
		current_action = "look"
	else:
		current_action = "use"
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "clear_action")

func _input(event):
	if !vm.can_interact():
		return
	if event.is_pressed() and event.is_action("inventory_toggle") and is_collapsible:
		toggle()

func log_button_pressed():
	close()
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "open_log")

func _on_open_inventory_signal(open):
	if (open):
		open()
	else:
		close()

func _ready():
	vm.connect("inventory_changed", self, "inventory_changed")
	vm.connect("open_inventory", self, "_on_open_inventory_signal")
	vm.connect("global_changed", self, "global_changed")

	page_size = get_node("slots").get_child_count()

	# XXX: Not sure why, but sorting a collapsible inventory here causes textures to disappear
	if not self.is_collapsible:
		sort_items()

	if has_node("arrow_prev"):
		$"arrow_prev".connect("pressed", self, "change_page", [-1])

	if has_node("arrow_next"):
		$"arrow_next".connect("pressed", self, "change_page", [1])

	var items = get_node("items")
	for i in range(0, items.get_child_count()):
		var c = items.get_child(i)
		#printt("c path is ", c.get_name(), c.get_filename())
		c.inventory = true
		c.use_action_menu = false
		c.hide()

	items.show()
	set_focus_mode(Control.FOCUS_NONE)
	#get_node("mask").set_focus_mode(Control.FOCUS_NONE)
	set_process_input(true)

	#get_node("log_button").connect("pressed", self, "log_button_pressed")

	if has_node("animation"):
		$"animation".connect("animation_finished", self, "anim_finished")

	add_to_group("game")

	call_deferred("sort_items")
