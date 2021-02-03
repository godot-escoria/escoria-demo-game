extends Node

"""
Implement methods to react to inputs.

- left_click_on_bg(position : Vector2)
- right_click_on_bg(position : Vector2)
- left_double_click_on_bg(position : Vector2)

- element_focused(element_id : String)
- element_unfocused()

- left_click_on_item(item_global_id : String, event : InputEvent)
- right_click_on_item(item_global_id : String, event : InputEvent)
- left_double_click_on_item(item_global_id : String, event : InputEvent)

- left_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent)
- right_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent)
- left_double_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent)
- inventory_item_focused(inventory_item_global_id : String)
- inventory_item_unfocused()
- open_inventory()
- close_inventory()

- mousewheel_action(direction : int)

- hide_ui()
- show_ui()

- _on_event_done(event_name: String)
"""

func _ready():
	escoria.esc_runner.connect("event_done", self, "_on_event_done")


func _input(event):
	if event.is_action_pressed("switch_action_verb"):
		if event.button_index == BUTTON_WHEEL_UP:
			escoria.inputs_manager._on_mousewheel_action(-1)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			escoria.inputs_manager._on_mousewheel_action(1)


## BACKGROUND ## 

func left_click_on_bg(position : Vector2) -> void:
	escoria.do("walk", ["player", position])
	escoria.esc_runner.clear_current_action()
	$ui/verbs_layer/verbs_menu.unselect_actions()
	
func right_click_on_bg(position : Vector2) -> void:
	escoria.do("walk", ["player", position])
	escoria.esc_runner.clear_current_action()
	$ui/verbs_layer/verbs_menu.unselect_actions()
	
func left_double_click_on_bg(position : Vector2) -> void:
	escoria.do("walk", ["player", position, true])
	escoria.esc_runner.clear_current_action()
	$ui/verbs_layer/verbs_menu.unselect_actions()


## ITEM FOCUS ## 

func element_focused(element_id : String) -> void:
	$ui/tooltip_layer/tooltip.set_target(escoria.esc_runner.get_object(element_id).tooltip_name)

func element_unfocused() -> void:
	$ui/tooltip_layer/tooltip.set_target("")


## ITEMS ##

func left_click_on_item(item_global_id : String, event : InputEvent) -> void:
	escoria.do("item_left_click", [item_global_id, event])

func right_click_on_item(item_global_id : String, event : InputEvent) -> void:
	escoria.do("item_right_click", [item_global_id, event])

func left_double_click_on_item(item_global_id : String, event : InputEvent) -> void:
	escoria.do("item_left_click", [item_global_id, event]) 


## INVENTORY ##
func left_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent) -> void:
	escoria.do("item_left_click", [inventory_item_global_id, event])
#	if escoria.esc_runner.current_action == "use":
#		var item = escoria.esc_runner.get_object(inventory_item_global_id)
#		if item.texture:
#			$ui/verbs_layer/verbs_menu.set_tool_texture(item.texture)
#		elif item.inventory_item_scene_file.instance().texture_normal:
#			$ui/verbs_layer/verbs_menu.set_tool_texture(item.inventory_item_scene_file.instance().texture_normal)
			

func right_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent) -> void:
	escoria.do("item_right_click", [inventory_item_global_id, event])

func left_double_click_on_inventory_item(inventory_item_global_id : String, event : InputEvent) -> void:
	pass

func inventory_item_focused(inventory_item_global_id : String) -> void:
	$ui/tooltip_layer/tooltip.set_target(escoria.esc_runner.get_object(inventory_item_global_id).tooltip_name)

func inventory_item_unfocused() -> void:
	$ui/tooltip_layer/tooltip.set_target("")


func open_inventory():
	$ui/inventory_layer/inventory_ui/inventory_button.show_inventory()


func close_inventory():
	$ui/inventory_layer/inventory_ui/inventory_button.close_inventory()

func mousewheel_action(direction : int):
	pass

func hide_ui():
	$ui/panel_down.hide()
	$ui/verbs_layer/verbs_menu.hide()
	$ui/inventory_layer/inventory_ui.hide()
	$ui/tooltip_layer/tooltip.hide()

func show_ui():
	$ui/panel_down.show()
	$ui/verbs_layer/verbs_menu.show()
	$ui/inventory_layer/inventory_ui.show()
	$ui/tooltip_layer/tooltip.show()

func _on_event_done(event_name: String):
	escoria.esc_runner.clear_current_action()
	$ui/verbs_layer/verbs_menu.unselect_actions()
