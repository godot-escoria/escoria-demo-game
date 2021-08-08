tool
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

- _on_event_done(event_name: String)
"""

onready var verbs_menu = $ui/panel_down/verbs_layer/verbs_menu
onready var tooltip = $ui/panel_down/tooltip_layer/tooltip

func _ready():
	ProjectSettings.set_setting("escoria/ui/tooltip_follows_mouse", false)

func _input(event):
	if event.is_action_pressed("switch_action_verb"):
		if event.button_index == BUTTON_WHEEL_UP:
			escoria.inputs_manager._on_mousewheel_action(-1)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			escoria.inputs_manager._on_mousewheel_action(1)


## BACKGROUND ## 

func left_click_on_bg(position: Vector2) -> void:
	escoria.do("walk", [escoria.main.current_scene.player.global_id, position])
	escoria.action_manager.clear_current_action()
	verbs_menu.unselect_actions()
	
	
func right_click_on_bg(position: Vector2) -> void:
	escoria.do("walk", [escoria.main.current_scene.player.global_id, position])
	escoria.action_manager.clear_current_action()
	verbs_menu.unselect_actions()
	
	
func left_double_click_on_bg(position: Vector2) -> void:
	escoria.do("walk", [escoria.main.current_scene.player.global_id, position, \
		true])
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
	verbs_menu.unselect_actions()


## ITEMS ##
func left_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.do("item_left_click", [item_global_id, event])


func right_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.set_current_action(verbs_menu.selected_action)
	escoria.do("item_right_click", [item_global_id, event])


func left_double_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.do("item_left_click", [item_global_id, event]) 


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
	$ui/panel_down.hide()
	verbs_menu.hide()
	$ui/panel_down/verbs_layer/room_select.hide()
	$ui/panel_down/inventory_layer/inventory_ui.hide()
	tooltip.hide()


func show_ui():
	$ui/panel_down.show()
	verbs_menu.show()
	$ui/panel_down/verbs_layer/room_select.show()
	$ui/panel_down/inventory_layer/inventory_ui.show()
	tooltip.show()

func _on_event_done(_event_name: String):
	escoria.action_manager.clear_current_action()
	verbs_menu.unselect_actions()


func pause_game():
	if $ui/pause_menu.visible:
		$ui/pause_menu.hide()
		escoria.main.current_scene.game.get_node("camera").current = true
		escoria.main.current_scene.game.show_ui()
		escoria.main.current_scene.show()
	else:
		$ui/pause_menu.show()
		escoria.main.current_scene.game.get_node("camera").current = false
		escoria.main.current_scene.game.hide_ui()
		escoria.main.current_scene.hide()
