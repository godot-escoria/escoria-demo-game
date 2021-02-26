tool
extends ESCGame

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
	ProjectSettings.set_setting("escoria/ui/tooltip_follows_mouse", true)


## BACKGROUND ## 

func left_click_on_bg(position : Vector2) -> void:
	escoria.do("walk", ["player", position])
	$ui/verbs_layer/verbs_menu.set_by_name("walk")
	$ui/verbs_layer/verbs_menu.clear_tool_texture()
	
func right_click_on_bg(position : Vector2) -> void:
	escoria.do("walk", ["player", position])
	$ui/verbs_layer/verbs_menu.set_by_name("walk")
	$ui/verbs_layer/verbs_menu.clear_tool_texture()
	
func left_double_click_on_bg(position : Vector2) -> void:
	escoria.do("walk", ["player", position, true])
	$ui/verbs_layer/verbs_menu.set_by_name("walk")
	$ui/verbs_layer/verbs_menu.clear_tool_texture()

## ITEM/HOTSPOT FOCUS ## 

func element_focused(element_id : String) -> void:
	var target_obj = escoria.esc_runner.get_object(element_id)
	$ui/tooltip_layer/tooltip.set_target(target_obj.tooltip_name)

	if escoria.esc_runner.current_action != "use" && escoria.esc_runner.current_tool == null:
		if target_obj is ESCItem:
			$ui/verbs_layer/verbs_menu.set_by_name(target_obj.default_action)

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
	if escoria.esc_runner.current_action == "use":
		var item = escoria.esc_runner.get_object(inventory_item_global_id)
		if item.get_node("sprite").texture:
			$ui/verbs_layer/verbs_menu.set_tool_texture(item.get_node("sprite").texture)
		elif item.inventory_item_scene_file.instance().texture_normal:
			$ui/verbs_layer/verbs_menu.set_tool_texture(item.inventory_item_scene_file.instance().texture_normal)
			

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
	$ui/verbs_layer/verbs_menu.iterate_actions_cursor(direction)

func hide_ui():
	$ui/inventory_layer/inventory_ui.hide()
	
func show_ui():
	$ui/inventory_layer/inventory_ui.show()

func _on_event_done(event_name: String):
	escoria.esc_runner.clear_current_action()
	$ui/verbs_layer/verbs_menu.clear_tool_texture()
