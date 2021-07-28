# Escoria inputs manager
# Catches, handles and distributes input events for the game
tool
extends Node


# A LIFO stack of hovered items
onready var hover_stack: Array = []

# The global id fo the topmost item from the hover_stack
onready var hotspot_focused: String = ""


# Input event handler
#
# #### Parameters
#
# - event: Godot input event received
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc_show_debug_prompt"):
		escoria.main.get_node("layers/debug_layer/esc_prompt_popup").popup()
	
	if event.is_action_pressed("ui_cancel"):
		_on_pause_menu_requested()
	
	if ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse"):
		if escoria.main.current_scene and escoria.main.current_scene.game:
			if event is InputEventMouseMotion:
				escoria.main.current_scene.game.update_tooltip_following_mouse_position(event.position)


# The background was clicked with the LMB
#
# #### Parameters
#
# - position: Position of the click
func _on_left_click_on_bg(position: Vector2) -> void:
	if hotspot_focused.empty():
		escoria.logger.info("Left click on background at ", [str(position)])
		escoria.main.current_scene.game.left_click_on_bg(position)


# The background was double-clicked with the LMB
#
# #### Parameters
#
# - position: Position of the click
func _on_double_left_click_on_bg(position: Vector2) -> void:
	if hotspot_focused.empty():
		escoria.logger.info("Double left click on background at ", [str(position)])
		escoria.main.current_scene.game.left_double_click_on_bg(position)


# The background was clicked with the RMB
#
# #### Parameters
#
# - position: Position of the click
func _on_right_click_on_bg(position: Vector2) -> void:
	if hotspot_focused.empty():
		escoria.logger.info("Right click on background at ", [str(position)])
		escoria.main.current_scene.game.right_click_on_bg(position)


# An inventory item was clicked with the LMB
#
# #### Parameters
# 
# - inventory_item_global_id: The global id of the clicked inventory item
# - event: The input event received
func _on_mouse_left_click_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	escoria.logger.info("Inventory item left clicked ", [inventory_item_global_id])
	escoria.main.current_scene.game.left_click_on_inventory_item(inventory_item_global_id, event)


# An inventory item was clicked with the RMB
#
# #### Parameters
#
# - inventory_item_global_id: The global id of the clicked inventory item
# - event: The input event received
func _on_mouse_right_click_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	escoria.logger.info("Inventory item right clicked ", [inventory_item_global_id])
	escoria.main.current_scene.game.right_click_on_inventory_item(inventory_item_global_id, event)


# An inventory item was doublce-clicked with the LMB
#
# #### Parameters
# 
# - inventory_item_global_id: The global id of the clicked inventory item
# - event: The input event received
func _on_mouse_double_left_click_inventory_item(inventory_item_global_id: String, event: InputEvent) -> void:
	escoria.logger.info("Inventory item double left clicked ", [inventory_item_global_id])
	escoria.main.current_scene.game.left_double_click_on_inventory_item(inventory_item_global_id, event)


# The mouse entered an inventory item
#
# #### Parameters
#
# - inventory_item_global_id: The global id of the inventory item that is hovered
func _on_mouse_entered_inventory_item(inventory_item_global_id: String) -> void:
	escoria.logger.info("Inventory item focused ", [inventory_item_global_id])
	escoria.main.current_scene.game.inventory_item_focused(inventory_item_global_id)


# The mouse exited an inventory item
func _on_mouse_exited_inventory_item() -> void:
	escoria.logger.info("Inventory item unfocused")
	escoria.main.current_scene.game.inventory_item_unfocused()


# The mouse entered an Escoria item
#
# #### Parameters
#
# - item: The Escoria item hovered
func _on_mouse_entered_item(item: ESCItem) -> void:
	escoria.logger.info("Item focused: ", [item.global_id])
	_clean_hover_stack()
	
	if not hover_stack.empty():
		if item.z_index < hover_stack.back().z_index:
			hover_stack.insert(hover_stack.size() - 1, item)
		else:
			hover_stack.push_back(item)
	else:
		hover_stack.push_back(item)
	
	hotspot_focused = hover_stack.back().global_id
	escoria.main.current_scene.game.element_focused(item.global_id)


# The mouse exited an Escoria item
#
# #### Parameters
#
# - item: The Escoria item hovered
func _on_mouse_exited_item(item: ESCItem) -> void:
	escoria.logger.info("Item unfocused: ", [item.global_id])
	_hover_stack_pop(item)
	if hover_stack.empty():
		hotspot_focused = ""
		escoria.main.current_scene.game.element_unfocused()
	else:
		hotspot_focused = hover_stack.back().global_id
		escoria.main.current_scene.game.element_focused(hotspot_focused)
	

# An Escoria item was clicked with the LMB
#
# #### Parameters
#
# - item: The Escoria item clicked
# - event: The input event from the click
func _on_mouse_left_clicked_item(item: ESCItem, event: InputEvent) -> void:
	if hover_stack.empty() or hover_stack.back() == item:
		escoria.logger.info("Item left clicked", [item.global_id, event])
		escoria.main.current_scene.game.left_click_on_item(item.global_id, event)


# An Escoria item was double-clicked with the LMB
#
# #### Parameters
#
# - item: The Escoria item clicked
# - event: The input event from the click
func _on_mouse_left_double_clicked_item(item: ESCItem, event: InputEvent) -> void:
	escoria.logger.info("Item left double clicked", [item.global_id, event])
	escoria.main.current_scene.game.left_double_click_on_item(item.global_id, event)


# An Escoria item was clicked with the RMB
#
# #### Parameters
#
# - item: The Escoria item clicked
# - event: The input event from the click
func _on_mouse_right_clicked_item(item: ESCItem, event: InputEvent) -> void:
	escoria.logger.info("Item right clicked", [item.global_id, event])
	escoria.main.current_scene.game.right_click_on_item(item.global_id, event)


# The mousewheel was turned
#
# #### Parameters
# 
# - direction: The direction the wheel was turned. 1 = up, -1 = down
func _on_mousewheel_action(direction: int):
	escoria.main.current_scene.game.mousewheel_action(direction)


# Event when the pause menu was requested
func _on_pause_menu_requested():
	escoria.main.current_scene.game.pause_game()


# Clean the hover stack
func _clean_hover_stack():
	for e in hover_stack:
		if e == null or !is_instance_valid(e):
			hover_stack.erase(e)


# Remove the given item from the stack
func _hover_stack_pop(item):
	hover_stack.erase(item)
