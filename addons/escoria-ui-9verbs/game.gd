extends ESCGame

"""
Implement methods to react to inputs.

- left_click_on_bg(position: Vector2)
- right_click_on_bg(position: Vector2)
- left_double_click_on_bg(position: Vector2)

- element_focused(element_id: String)
- element_unfocused()

- left_click_on_item(item_global_id: String, event: InputEvent)
- right_click_on_item(item_global_id: String, event: InputEvent)
- left_double_click_on_item(item_global_id: String, event: InputEvent)

- left_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent)
- right_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent)
- left_double_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent)
- inventory_item_focused(inventory_item_global_id: String)
- inventory_item_unfocused()
- open_inventory()
- close_inventory()

- mousewheel_action(direction: int)

- hide_ui()
- show_ui()

- pause_game()
- unpause_game()
- show_main_menu()
- hide_main_menu()

- _on_event_done(event_name: String)
"""

onready var verbs_menu = $ui/Control/panel_down/VBoxContainer/HBoxContainer\
		/VerbsMargin/verbs_menu
onready var tooltip = $ui/Control/panel_down/VBoxContainer/MarginContainer\
		/tooltip
onready var room_select = $ui/Control/panel_down/VBoxContainer/HBoxContainer\
		/MainMargin/VBoxContainer/room_select
onready var inventory_ui = $ui/Control/panel_down/VBoxContainer/HBoxContainer\
		/InventoryMargin/inventory_ui

func _enter_tree():
	ProjectSettings.set_setting("escoria/ui/tooltip_follows_mouse", false)
	escoria.action_manager.connect(
		"action_finished", 
		self, 
		"_on_action_finished"
	)
	
	var room_selector_parent = $ui/Control/panel_down/VBoxContainer\
			/HBoxContainer/MainMargin/VBoxContainer
	
	if ProjectSettings.get_setting("escoria/debug/enable_room_selector") and \
			room_selector_parent.get_node_or_null("room_select") == null:
		room_selector_parent.add_child(
			preload(
				"res://addons/escoria-core/ui_library/tools/room_select" +\
				"/room_select.tscn"
			).instance()
		)

func _exit_tree():
	escoria.action_manager.disconnect(
		"action_finished", 
		self, 
		"_on_action_finished"
	)


## BACKGROUND ## 

func left_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		escoria.do(
			"walk", 
			[escoria.main.current_scene.player.global_id, position],
			true
		)
		escoria.action_manager.clear_current_action()
		verbs_menu.unselect_actions()
	
	
func right_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		escoria.do(
			"walk", 
			[escoria.main.current_scene.player.global_id, position],
			true
		)
		escoria.action_manager.clear_current_action()
		verbs_menu.unselect_actions()
	
	
func left_double_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		escoria.do(
			"walk", 
			[escoria.main.current_scene.player.global_id, position, true], 
			true
		)
		escoria.action_manager.clear_current_action()
		verbs_menu.unselect_actions()


## ITEM FOCUS ## 

func element_focused(element_id: String) -> void:
	var target_obj = escoria.object_manager.get_object(element_id).node
	tooltip.set_target(target_obj.tooltip_name)
	
	if escoria.action_manager.current_action != "use" \
			and escoria.action_manager.current_tool == null:
		if target_obj is ESCItem:
			verbs_menu.set_by_name(target_obj.default_action)


func element_unfocused() -> void:
	tooltip.clear()


## ITEMS ##
func left_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.do("item_left_click", [item_global_id, event], true)


func right_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.set_current_action(verbs_menu.selected_action)
	escoria.do("item_right_click", [item_global_id, event], true)


func left_double_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.do("item_left_click", [item_global_id, event], true) 


## INVENTORY ##
func left_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	escoria.do("item_left_click", [inventory_item_global_id, event])
			

func right_click_on_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.set_current_action(verbs_menu.selected_action)
	escoria.do("item_right_click", [inventory_item_global_id, event])


func left_double_click_on_inventory_item(_inventory_item_global_id: String, _event: InputEvent) -> void:
	pass


func inventory_item_focused(inventory_item_global_id: String) -> void:
	var target_obj = escoria.object_manager.get_object(
		inventory_item_global_id
	).node
	tooltip.set_target(target_obj.tooltip_name)
	
	if escoria.action_manager.current_action != "use" \
			and escoria.action_manager.current_tool == null:
		if target_obj is ESCItem:
			verbs_menu.set_by_name(target_obj.default_action_inventory)
	

func inventory_item_unfocused() -> void:
	tooltip.set_target("")
	verbs_menu.unselect_actions()


func open_inventory():
	pass


func close_inventory():
	pass


func mousewheel_action(_direction: int):
	pass


func hide_ui():
	$ui/Control.hide()
	verbs_menu.hide()
	room_select.hide()
	inventory_ui.hide()
	tooltip.hide()


func show_ui():
	$ui/Control.show()
	verbs_menu.show()
	room_select.show()
	inventory_ui.show()
	tooltip.show()

func _on_event_done(_event_name: String):
	escoria.action_manager.clear_current_action()
	verbs_menu.unselect_actions()

func hide_main_menu():
	if get_node(main_menu).visible:
		get_node(main_menu).hide()

func show_main_menu():
	if not get_node(main_menu).visible:
		get_node(main_menu).show()
	
func unpause_game():
	if get_node(pause_menu).visible:
		get_node(pause_menu).hide()
		escoria.object_manager.get_object("_camera").node.current = true
		escoria.main.current_scene.game.show_ui()
		escoria.main.current_scene.show()
		escoria.set_game_paused(false)

func pause_game():
	if not get_node(pause_menu).visible:
		get_node(pause_menu).set_save_enabled(escoria.save_manager.save_enabled)
		get_node(pause_menu).show()
		escoria.object_manager.get_object("_camera").node.current = false
		escoria.main.current_scene.game.hide_ui()
		escoria.main.current_scene.hide()
		escoria.set_game_paused(true)


func _on_MenuButton_pressed() -> void:
	pause_game()
	
	
func _on_action_finished() -> void:
	verbs_menu.unselect_actions()


func show_crash_popup(files = []) -> void:
	connect("crash_popup_confirmed", escoria, "quit", 
		[], CONNECT_ONESHOT)
	var crash_popup = escoria.resource_cache.get_resource(
		"res://addons/escoria-core/ui_library/crash_popup/crash_popup.tscn"
	).instance()
	add_child(crash_popup)
	move_child(crash_popup, 0)
	var files_to_send: String = ""
	for file in files:
		files_to_send += "- %s\n" % file
	crash_popup.set_message(
		ProjectSettings.get_setting("escoria/debug/crash_message") 
			% files_to_send
	)
	crash_popup.popup_centered()
	escoria.set_game_paused(true)
	yield(crash_popup, "confirmed")
	emit_signal("crash_popup_confirmed")
