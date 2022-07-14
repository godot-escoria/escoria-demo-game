# Escoria inputs manager
# Catches, handles and distributes input events for the game
extends Resource
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

# Input action for use by InputMap that represents a "primary action" from an
# input device, such as a left-click on a mouse or the X button on an XBox
# controller
const ESC_UI_PRIMARY_ACTION = "esc_ui_primary_action"

# The current input mode
var input_mode = INPUT_ALL

# A LIFO stack of hovered items
var hover_stack: Array = []

# The global id of the topmost item from the hover_stack
var hotspot_focused: String = ""

# Function reference that can be used to intercept and process input events.
# If set, this function must have the following signature:
#
# (event: InputEvent, is_default_state: bool) -> bool
#
# #### Parameters
#
# - event: The event to process
# - is_default_state: Whether the current state is escoria.GAME_STATE.DEFAULT
#
# **Returns** Whether the function processed the event.
var custom_input_handler = null

# Register core signals (from escoria.gd)
func register_core():
	escoria.game_scene.connect(
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


# Registers a function that can be used to intercept and process input events.
# `callback` must have the following signature:
#
# (event: InputEvent, is_default_state: bool) -> bool
#
# where
#
# - event: The event to process
# - is_default_state: Whether the current state is escoria.GAME_STATE.DEFAULT
# - returns whether the function processed the event
#
# `callback` is responsible for calling `get_tree().set_input_as_handled()`,
# if appropriate.
#
# #### Parameters
# - callback: Function reference satisfying the above contract
func register_custom_input_handler(callback) -> void:
	custom_input_handler = callback


# If a callback was specified via `register_custom_input_handler()`,
# forwards the event to the callback and returns its result; otherwise,
# returns `false`.
#
# #### Parameters
#
# - event: The event to process
# - is_default_state: Whether the current state is escoria.GAME_STATE.DEFAULT
#
# **Returns** Result of `custom_input_handler` if set; otherwise, `false`
func try_custom_input_handler(event: InputEvent, is_default_state: bool) -> bool:
	if custom_input_handler:
		return custom_input_handler.call_func(event, is_default_state)
	else:
		return false


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
		escoria.logger.info(
			self,
			"Left click on background at %s." % str(position)
		)
		escoria.main.current_scene.game.left_click_on_bg(position)


# The background was double-clicked with the LMB
#
# #### Parameters
#
# - position: Position of the click
func _on_double_left_click_on_bg(position: Vector2) -> void:
	if input_mode == INPUT_ALL and hotspot_focused.empty():
		escoria.logger.info(
			self,
			"Double left click on background at %s." % str(position)
		)
		escoria.main.current_scene.game.left_double_click_on_bg(position)


# The background was clicked with the RMB
#
# #### Parameters
#
# - position: Position of the click
func _on_right_click_on_bg(position: Vector2) -> void:
	if input_mode == INPUT_ALL and hotspot_focused.empty():
		escoria.logger.info(
			self,
			"Right click on background at %s." % str(position)
		)
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
		self,
		"Inventory item %s left clicked." % inventory_item_global_id
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
			self,
			"Inventory item %s right clicked." % inventory_item_global_id
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
			self,
			"Inventory item %s double left clicked." % inventory_item_global_id
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
		self,
		"Inventory item %s focused." % inventory_item_global_id
	)
	escoria.main.current_scene.game.inventory_item_focused(
		inventory_item_global_id
	)


# The mouse exited an inventory item
func _on_mouse_exited_inventory_item() -> void:
	escoria.logger.info(
		self,
		"Inventory item unfocused."
	)
	escoria.main.current_scene.game.inventory_item_unfocused()


# The mouse entered an Escoria item
#
# #### Parameters
#
# - item: The Escoria item hovered
func _on_mouse_entered_item(item: ESCItem) -> void:
	var object: ESCObject = escoria.object_manager.get_object(item.global_id)
	if object and not object.interactive:
		_hover_stack_erase_item(item)
		hotspot_focused = ""
		escoria.main.current_scene.game.element_unfocused()
		return
	
	if object and not object.interactive:
		return
	if object and object.node is ESCPlayer and not (object.node as ESCPlayer).selectable:
		return
	escoria.logger.info(
		self,
		"Item focused: %s" % item.global_id
	)
	_clean_hover_stack()

	if not hover_stack.empty():
		if item.z_index < hover_stack.back().z_index:
			hover_stack.insert(hover_stack.size() - 1, item)
		else:
			hover_stack.push_back(item)
	else:
		hover_stack.push_back(item)

	hotspot_focused = hover_stack.back().global_id
	escoria.main.current_scene.game.element_focused(hotspot_focused)


# The mouse exited an Escoria item
#
# #### Parameters
#
# - item: The Escoria item hovered
func _on_mouse_exited_item(item: ESCItem) -> void:
	var object: ESCObject = escoria.object_manager.get_object(item.global_id)
	if object and not object.interactive:
		_hover_stack_erase_item(item)
		hotspot_focused = ""
		escoria.main.current_scene.game.element_unfocused()
		return
	
	if object and not object.interactive:
		return
	if object and object.node is ESCPlayer and not (object.node as ESCPlayer).selectable:
		return
	escoria.logger.info(
		self,
		"Item unfocused: %s" % item.global_id
	)
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
		var actual_item
		if hover_stack.empty() or hover_stack.back() == item:
			actual_item = item
		else:
			actual_item = hover_stack.back()
		
		if actual_item == null:
			escoria.logger.error(
				self,
				"Clicked item %s cannot be activated (player not selectable or not interactive). " 
						% [item.global_id, event] +
				"No valid item found in the items stack. Action cancelled."
			)
			return

		# We check if the clicked object is ESCPlayer and not selectable. If so
		# we consider we clicked through it.
		var object: ESCObject = escoria.object_manager.get_object(item.global_id)
		if object.node is ESCPlayer and not (object.node as ESCPlayer).selectable:
			if event.position:
				(escoria.main.current_scene.game as ESCGame).left_click_on_bg(event.position)
		else:
			hotspot_focused = actual_item.global_id
			escoria.main.current_scene.game.left_click_on_item(
				actual_item.global_id,
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
		var actual_item
		if hover_stack.empty() or hover_stack.back() == item:
			actual_item = item
		else:
			actual_item = hover_stack.back()
		
		if actual_item == null:
			escoria.logger.error(
				self,
				"Clicked item %s cannot be activated (player not selectable or not interactive). " 
						% [item.global_id, event] +
				"No valid item found in the items stack. Action cancelled."
			)
			return
			
		# We check if the clicked object is ESCPlayer and not selectable. If so
		# we consider we clicked through it.
		var object: ESCObject = escoria.object_manager.get_object(item.global_id)
		if object.node is ESCPlayer and not (object.node as ESCPlayer).selectable:
			if event.position:
				(escoria.main.current_scene.game as ESCGame).left_click_on_bg(event.position)
		else:
			escoria.logger.info(
				self,
				"Item %s left double clicked with event %s." % [actual_item.global_id, event]
			)
			hotspot_focused = actual_item.global_id
			escoria.main.current_scene.game.left_double_click_on_item(
				actual_item.global_id,
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
		var actual_item
		if hover_stack.empty() or hover_stack.back() == item:
			actual_item = item
		else:
			actual_item = hover_stack.back()
		
		if actual_item == null:
			escoria.logger.error(
				self,
				"Clicked item %s cannot be activated (player not selectable or not interactive). " 
						% [item.global_id, event] +
				"No valid item found in the items stack. Action cancelled."
			)
			return
		
		# We check if the clicked object is ESCPlayer and not selectable. If so
		# we consider we clicked through it.
		var object: ESCObject = escoria.object_manager.get_object(item.global_id)
		if object.node is ESCPlayer and not (object.node as ESCPlayer).selectable:
			if event.position:
				(escoria.main.current_scene.game as ESCGame).right_click_on_bg(event.position)
		else:
			escoria.logger.info(
				self,
				"Item %s right clicked with event %s." % [actual_item.global_id, event]
			)
			hotspot_focused = actual_item.global_id
			escoria.main.current_scene.game.right_click_on_item(
				actual_item.global_id,
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
