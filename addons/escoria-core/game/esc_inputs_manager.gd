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

# The currently hovered element. Usually the one on top of the hover stack.
var _hovered_element = null


# Constructor
func _init():
	escoria.event_manager.connect("event_finished", self, "_on_event_finished")


# Called when an event is finished, so that the current hotspot is reset
#
# #### Parameters
#
# - return_code: The return code of the event
# - event_name: the name of the event
#
func _on_event_finished(return_code: int, event_name: String):
	if _hovered_element == null:
		hotspot_focused = ""


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



# Unsets the hovered node.
#
# **Parameters**
#
# - item: the item that was unfocused (mouse_exited)
func unset_hovered_node(item: ESCItem):
	if _hovered_element == item:
		_hovered_element.mouse_exited()
		_hovered_element = null
		if hover_stack.back():
			set_hovered_node(hover_stack.pop_back())
		else:
			hotspot_focused = ""




# Sets the hovered node and calls its mouse_entered() method if it was the top
# most item in hover_stack.
#
# #### Parameters
#
# - item: the item that was focused (mouse_entered)
#
# **Returns**
# True if item is the new top hovered object
func set_hovered_node(item: ESCItem) -> bool:
	# If tested item was already hovered
	# or is not actionable (not selectable for ESCPlayer) then do nothing
	if _hovered_element == item \
			or not escoria.action_manager.is_object_actionable(item.global_id) \
			or (item is ESCPlayer and not (item as ESCPlayer).selectable):
		return true
	# Else if the tested item is on top of hover stack (or null)
	# Set that item as hovered and call that item's mouse_entered()
	if _hovered_element == null or hover_stack.back() != item:
		_hovered_element = item
		_hovered_element.mouse_entered()
		return true
	# Else, the tested item is currently on top of hover stack, then do nothing
	else:
		return false


# The background was clicked with the LMB
#
# #### Parameters
#
# - position: Position of the click
func _on_left_click_on_bg(position: Vector2) -> void:
	if input_mode == INPUT_ALL: # and hotspot_focused.empty():
		hotspot_focused = ""
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
	if input_mode == INPUT_ALL: # and hotspot_focused.empty():
		hotspot_focused = ""
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
	if item as ESCPlayer and not (item as ESCPlayer).selectable:
		escoria.logger.trace(
			self,
			"Ignoring mouse entering player %s: Player not selectable." % [item.global_id]
		)
		if hover_stack.empty():
			hotspot_focused = ""
			escoria.main.current_scene.game.element_unfocused()
		else:
			hotspot_focused = hover_stack.back().global_id
			escoria.main.current_scene.game.element_focused(hotspot_focused)
		return

	if not escoria.action_manager.is_object_actionable(item.global_id):
		escoria.logger.debug(
			self,
			"Ignoring mouse entering item %s." % [item.global_id]
		)
		return

	escoria.logger.info(
		self,
		"Item focused: %s" % item.global_id
	)

	hotspot_focused = item.global_id
	escoria.main.current_scene.game.element_focused(item.global_id)


# The mouse exited an Escoria item
#
# #### Parameters
#
# - item: The Escoria item hovered
func _on_mouse_exited_item(item: ESCItem) -> void:
	var object: ESCObject = escoria.object_manager.get_object(item.global_id)
	if object and not object.interactive:
		hover_stack_erase_item(item)
		escoria.main.current_scene.game.element_unfocused()
		return

	if object and not object.interactive:
		return
	if object and object.node is ESCPlayer and not (object.node as ESCPlayer).selectable:
		hotspot_focused = ""
		return

	escoria.logger.info(
		self,
		"Item unfocused: %s" % hotspot_focused
	)

	if hover_stack.empty():
		hotspot_focused = ""
		escoria.main.current_scene.game.element_unfocused()
	else:
		hotspot_focused = hover_stack.back().global_id
		escoria.main.current_scene.game.element_focused(hotspot_focused)


# Function called when the item is set interactive, to re-trigger an input on
# underlying item.
#
# #### Parameters
#
# - item: The ESCCItem that was set non-interactive
func on_item_non_interactive(item: ESCItem) -> void:
	var object: ESCObject = escoria.object_manager.get_object(item.global_id)
	if object and not object.interactive:
		hover_stack_erase_item(item)
		escoria.main.current_scene.game.element_unfocused()
		hover_stack.sort_custom(HoverStackSorter, "sort_ascending_z_index")
		if hover_stack.empty():
			return
		else:
			var new_item = hover_stack.back()
			escoria.action_manager.set_action_input_state(ESCActionManager.ACTION_INPUT_STATE.AWAITING_VERB_OR_ITEM)
			new_item.mouse_entered()

# An Escoria item was clicked with the LMB
#
# #### Parameters
#
# - item: The Escoria item clicked
# - event: The input event from the click
func _on_mouse_left_clicked_item(item: ESCItem, event: InputEvent) -> void:
	if input_mode == INPUT_ALL:
		# Manage clicking through ESCPlayer (if ESCPlayer.selectable is false)
		if item as ESCPlayer and not (item as ESCPlayer).selectable:
			escoria.logger.trace(
				self,
				"Ignoring left click on player %s: Player not selectable."
						% [item.global_id]
			)

			# Get next object in hover stack and forward event to it
			if not hover_stack.empty():
				var next_item = hover_stack.pop_back()
				_on_mouse_left_clicked_item(next_item, event)
			else: # if no next object, consider this click as background click
				hotspot_focused = ""
				_on_left_click_on_bg(event.position)
			return

		# Clicked object can't be actioned and there is no other object behind
		# We consider this click as a background click
		if not escoria.action_manager.is_object_actionable(item.global_id) \
				and hover_stack.empty():
			hotspot_focused = ""
			_on_left_click_on_bg(event.position)
			return

		# Finally, execute the action on the ESCItem
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
		# Manage clicking through ESCPlayer (if ESCPlayer.selectable is false)
		if item as ESCPlayer and not (item as ESCPlayer).selectable:
			escoria.logger.trace(
				self,
				"Ignoring double left click on player %s: Player not selectable."
						% [item.global_id]
			)

			# Get next object in hover stack and forward event to it
			if not hover_stack.empty():
				var next_item = hover_stack.pop_back()
				_on_mouse_left_double_clicked_item(next_item, event)
			else: # if no next object, consider this click as background click
				hotspot_focused = ""
				_on_double_left_click_on_bg(event.position)
			return

		# Clicked object can't be actioned and there is no other object behind
		# We consider this click as a background click
		if not escoria.action_manager.is_object_actionable(item.global_id) \
				and hover_stack.empty():
			hotspot_focused = ""
			_on_double_left_click_on_bg(event.position)
			return

		# Finally, execute the action on the ESCItem
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
		if item as ESCPlayer and not (item as ESCPlayer).selectable:
			escoria.logger.debug(
				self,
				"Ignoring right click on player %s: Player not selectable." % [item.global_id]
			)

			if not hover_stack.empty():
				var next_item = hover_stack.pop_back()
				_on_mouse_right_clicked_item(next_item, event)
			return

		if not escoria.action_manager.is_object_actionable(item.global_id) \
				and hover_stack.empty():
			# Treat this as a background click now
			hotspot_focused = ""
			_on_right_click_on_bg(event.position)
			return

		var actual_item

		# We check if the clicked object is ESCPlayer and not selectable. If so
		# we consider we clicked through it.
		var object: ESCObject = escoria.object_manager.get_object(item.global_id)
		if object.node is ESCPlayer and not (object.node as ESCPlayer).selectable:
			actual_item = hover_stack.back()
		else:
			actual_item = item

		if actual_item == null:
			if event.position:
				(escoria.main.current_scene.game as ESCGame).right_click_on_bg(event.position)
			else:
				escoria.logger.info(
					self,
					"Clicked item %s with event %s cannot be activated (player not selectable or not interactive).\n"
							% [item.global_id, event] +
					"No valid item found in the items stack. Action cancelled."
				)
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


# Add the given item to the stack if not already in it.
#
# #### Parameters
# - item: the item to add to the hover stack
func hover_stack_add_item(item):
	if item is ESCPlayer and not (item as ESCPlayer).selectable:
		return
	if not hover_stack.has(item):
		hover_stack.push_back(item)
		hover_stack.sort_custom(HoverStackSorter, "sort_ascending_z_index")


# Add the items contained in given list to the stack if not already in it.
#
# #### Parameters
# - items: the items list (array) to add to the hover stack
func hover_stack_add_items(items: Array):
	for item in items:
		if escoria.action_manager.is_object_actionable(item.global_id):
			hover_stack_add_item(item)


# Clean the hover stack
func _clean_hover_stack():
	for e in hover_stack:
		if e == null or !is_instance_valid(e):
			hover_stack.erase(e)


# Remove the given item from the stack
#
# #### Parameters
# - item: the item to remove from the hover stack
func hover_stack_erase_item(item):
	hover_stack.erase(item)
	hover_stack.sort_custom(HoverStackSorter, "sort_ascending_z_index")


# Clear the stack of hovered items
func hover_stack_clear():
	hover_stack = []


class HoverStackSorter:
	static func sort_ascending_z_index(a, b):
		if a.z_index < b.z_index:
			return true
		return false
