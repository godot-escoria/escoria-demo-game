# Escoria inputs manager
# Catches, handles and distributes input events for the game
extends Node
class_name ESCInputsManager


# Valid input flags
# * INPUT_ALL: All input is allowed
# * INPUT_NONE: No input is allowed at all
# * INPUT_SKIP: Only skipping dialogs is allowed
enum {
	INPUT_ALL,
	INPUT_NONE,
	INPUT_SKIP,
}


# Input action for use by InputMap
const SWITCH_ACTION_VERB = "switch_action_verb"

# Input action for use by InputMap
const ESC_SHOW_DEBUG_PROMPT = "esc_show_debug_prompt"


# The current input mode
var input_mode = INPUT_ALL

# A LIFO stack of hovered items
var hover_stack: Array = []

# The global id of the topmost item from the hover_stack
var hotspot_focused: String = ""


# Register core signals (from escoria.gd)
func register_core():
	escoria.connect(
		"request_pause_menu",
		self,
		"_on_pause_menu_requested"
	)


# Connect the item signals to the local methods
func register_inventory_item(item: Node):
	item.connect(
		"mouse_left_inventory_item", 
		self, 
		"_on_mouse_left_click_inventory_item"
	)
	item.connect(
		"mouse_double_left_inventory_item", 
		self, 
		"_on_mouse_double_left_click_inventory_item"
	)
	item.connect(
		"mouse_right_inventory_item", 
		self,
		"_on_mouse_right_click_inventory_item"
	)
	
	item.connect(
		"inventory_item_focused", 
		self, 
		"_on_mouse_entered_inventory_item"
	)
	item.connect(
		"inventory_item_unfocused", 
		self, 
		"_on_mouse_exited_inventory_item"
	)
	

func register_background(background: ESCBackground):
	background.connect(
		"left_click_on_bg", 
		self, 
		"_on_left_click_on_bg"
	)
	background.connect(
		"right_click_on_bg", 
		escoria.inputs_manager, 
		"_on_right_click_on_bg"
	)
	background.connect(
		"double_left_click_on_bg", 
		escoria.inputs_manager, 
		"_on_double_left_click_on_bg"
	)
	background.connect(
		"mouse_wheel_up",
		self,
		"_on_mousewheel_action",
		[1]
	)
	background.connect(
		"mouse_wheel_down",
		self,
		"_on_mousewheel_action",
		[-1]
	)
	
	
# Clear the stack of hovered items
func clear_stack():
	hover_stack = []


# The background was clicked with the LMB
#
# #### Parameters
#
# - position: Position of the click
func _on_left_click_on_bg(position: Vector2) -> void:
	if input_mode == INPUT_ALL and hotspot_focused.empty():
		escoria.logger.info("Left click on background at ", [str(position)])
		escoria.main.current_scene.game.left_click_on_bg(position)


# The background was double-clicked with the LMB
#
# #### Parameters
#
# - position: Position of the click
func _on_double_left_click_on_bg(position: Vector2) -> void:
	if input_mode == INPUT_ALL and hotspot_focused.empty():
		escoria.logger.info(
			"Double left click on background at %s" % str(position)
		)
		escoria.main.current_scene.game.left_double_click_on_bg(position)


# The background was clicked with the RMB
#
# #### Parameters
#
# - position: Position of the click
func _on_right_click_on_bg(position: Vector2) -> void:
	if input_mode == INPUT_ALL and hotspot_focused.empty():
		escoria.logger.info("Right click on background at ", [str(position)])
		escoria.main.current_scene.game.right_click_on_bg(position)


# An inventory item was clicked with the LMB
#
# #### Parameters
# 
# - inventory_item_global_id: The global id of the clicked inventory item
# - event: The input event received
func _on_mouse_left_click_inventory_item(
	inventory_item_global_id: String, 
	event: InputEvent
) -> void:
	escoria.logger.info(
		"Inventory item left clicked %s " % inventory_item_global_id
	)
	escoria.main.current_scene.game.left_click_on_inventory_item(
		inventory_item_global_id, 
		event
	)


# An inventory item was clicked with the RMB
#
# #### Parameters
#
# - inventory_item_global_id: The global id of the clicked inventory item
# - event: The input event received
func _on_mouse_right_click_inventory_item(
	inventory_item_global_id: String, 
	event: InputEvent
) -> void:
	if input_mode == INPUT_ALL:
		escoria.logger.info(
			"Inventory item right clicked %s" % inventory_item_global_id
		)
		escoria.main.current_scene.game.right_click_on_inventory_item(
			inventory_item_global_id, 
			event
		)


# An inventory item was doublce-clicked with the LMB
#
# #### Parameters
# 
# - inventory_item_global_id: The global id of the clicked inventory item
# - event: The input event received
func _on_mouse_double_left_click_inventory_item(
	inventory_item_global_id: String, 
	event: InputEvent
) -> void:
	if input_mode == INPUT_ALL:
		escoria.logger.info(
			"Inventory item double left clicked %s" % inventory_item_global_id
		)
		escoria.main.current_scene.game.left_double_click_on_inventory_item(
			inventory_item_global_id, 
			event
		)


# The mouse entered an inventory item
#
# #### Parameters
#
# - inventory_item_global_id: The global id of the inventory item 
#	that is hovered
func _on_mouse_entered_inventory_item(inventory_item_global_id: String) -> void:
	escoria.logger.info(
		"Inventory item focused %s" % inventory_item_global_id
	)
	escoria.main.current_scene.game.inventory_item_focused(
		inventory_item_global_id
	)


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
	_hover_stack_erase_item(item)
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
	if input_mode == INPUT_ALL:
		if hover_stack.empty() or hover_stack.back() == item:
			escoria.logger.info("Item left clicked", [item.global_id, event])
			hotspot_focused = item.global_id
			escoria.main.current_scene.game.left_click_on_item(
				item.global_id, 
				event
			)


# An Escoria item was double-clicked with the LMB
#
# #### Parameters
#
# - item: The Escoria item clicked
# - event: The input event from the click
func _on_mouse_left_double_clicked_item(
	item: ESCItem,
	event: InputEvent
) -> void:
	if input_mode == INPUT_ALL:
		escoria.logger.info("Item left double clicked", [item.global_id, event])
		hotspot_focused = item.global_id
		escoria.main.current_scene.game.left_double_click_on_item(
			item.global_id, 
			event
		)


# An Escoria item was clicked with the RMB
#
# #### Parameters
#
# - item: The Escoria item clicked
# - event: The input event from the click
func _on_mouse_right_clicked_item(item: ESCItem, event: InputEvent) -> void:
	if input_mode == INPUT_ALL:
		escoria.logger.info("Item right clicked", [item.global_id, event])
		hotspot_focused = item.global_id
		escoria.main.current_scene.game.right_click_on_item(
			item.global_id, 
			event
		)


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
#
# #### Parameters
# - item: the item to remove from the hover stack
func _hover_stack_erase_item(item):
	hover_stack.erase(item)
