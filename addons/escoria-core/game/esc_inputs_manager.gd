## Escoria inputs manager
##
## Catches, handles and distributes input events for the game.
extends Resource
class_name ESCInputsManager


## Valid input flags[br]
## * INPUT_ALL: All input is allowed[br]
## * INPUT_NONE: No input is allowed at all[br]
## * INPUT_SKIP: Only skipping dialogs is allowed
enum {
	INPUT_ALL,
	INPUT_NONE,
	INPUT_SKIP,
}


## Input action for use by InputMap
const ESC_SHOW_DEBUG_PROMPT = "esc_show_debug_prompt"

## Input action for use by InputMap that represents a "primary action" from an
## input device, such as a left-click on a mouse or the X button on an XBox
## controller
const ESC_UI_PRIMARY_ACTION = "esc_ui_primary_action"


## The current input mode
var input_mode = INPUT_ALL

## A LIFO stack of hovered items
var hover_stack: HoverStack

## The global id of the topmost item from the hover_stack
var hotspot_focused: String = ""

## Function reference that can be used to intercept and process input events.
## If set, this function must have the following signature:[br]
##[br]
## (event: InputEvent, is_default_state: bool) -> bool[br]
##[br]
## #### Parameters[br]
##[br]
## - event: The event to process[br]
## - is_default_state: Whether the current state is escoria.GAME_STATE.DEFAULT[br]
##[br]
## **Returns** Whether the function processed the event.
var custom_input_handler = null

# The currently hovered element. Usually the one on top of the hover stack.
var _hovered_element = null


# Constructor
func _init():
	escoria.event_manager.connect("event_finished", Callable(self, "_on_event_finished"))
	hover_stack = HoverStack.new()
	hover_stack.connect("hover_stack_changed", Callable(self, "_on_hover_stack_changed"))


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


## Register core signals (from escoria.gd)
func register_core():
	escoria.game_scene.request_pause_menu.connect(_on_pause_menu_requested)


## Connects the item signals to local methods
func register_inventory_item(item: Node):
	item.mouse_left_inventory_item.connect(_on_mouse_left_click_inventory_item)
	item.mouse_double_left_inventory_item.connect(_on_mouse_double_left_click_inventory_item)
	item.mouse_right_inventory_item.connect(_on_mouse_right_click_inventory_item)
	item.inventory_item_focused.connect(_on_mouse_entered_inventory_item)
	item.inventory_item_unfocused.connect(_on_mouse_exited_inventory_item)


## Connects the background signals to local methods
func register_background(background: ESCBackground):
	background.left_click_on_bg.connect(_on_left_click_on_bg)
	background.right_click_on_bg.connect(_on_right_click_on_bg)
	background.double_left_click_on_bg.connect(_on_double_left_click_on_bg)
	background.mouse_wheel_up.connect(_on_mousewheel_action.bind(1))
	background.mouse_wheel_down.connect(_on_mousewheel_action.bind(-1))
	background.hovered_bg.connect(_on_hover_bg)


## Registers a function that can be used to intercept and process input events.
## `callback` must have the following signature:[br]
##[br]
## (event: InputEvent, is_default_state: bool) -> bool[br]
##[br]
## ...where:[br]
##[br]
## - event: The event to process[br]
## - is_default_state: Whether the current state is escoria.GAME_STATE.DEFAULT[br]
## - returns whether the function processed the event[br]
##[br]
## `callback` is responsible for calling `get_tree().set_input_as_handled()`, 
## if appropriate.[br]
##[br]
## #### Parameters[br]
## - callback: Function reference satisfying the above contract
func register_custom_input_handler(callback) -> void:
	custom_input_handler = callback


## If a callback was specified via `register_custom_input_handler()`,
## forwards the event to the callback and returns its result; otherwise,
## returns `false`.[br]
##[br]
## #### Parameters[br]
##[br]
## - event: The event to process[br]
## - is_default_state: Whether the current state is escoria.GAME_STATE.DEFAULT[br]
##[br]
## **Returns** Result of `custom_input_handler` if set; otherwise, `false`
func try_custom_input_handler(event: InputEvent, is_default_state: bool) -> bool:
	if custom_input_handler:
		return custom_input_handler.call(event, is_default_state)
	else:
		return false


# Callback called by hover stack content change.
func _on_hover_stack_changed():
	if hover_stack.is_empty():
		unset_hovered_node(_hovered_element)
	else:
		set_hovered_node(hover_stack.get_top_item())


## Sets the hovered node and calls its mouse_entered() method if it was the top
## most item in hover_stack.[br]
##[br]
## #### Parameters[br]
##[br]
## - item: the item that was focused (mouse_entered)[br]
##[br]
## **Returns** True if item is the new top hovered object
func set_hovered_node(item: ESCItem) -> bool:
	if _hovered_element != item \
			and escoria.action_manager.is_object_actionable(item.global_id) \
			or (item is ESCPlayer and not (item as ESCPlayer).selectable):
		_hovered_element = item
		_hovered_element.mouse_entered()
		return true
	# If tested item was already hovered
	# or is not actionable (not selectable for ESCPlayer) then do nothing
	if _hovered_element == item \
			or not escoria.action_manager.is_object_actionable(item.global_id) \
			or (item is ESCPlayer and not (item as ESCPlayer).selectable):
		return true
	# Else if the tested item is on top of hover stack (or null)
	# Set that item as hovered and call that item's mouse_entered()
	if not is_instance_valid(_hovered_element) or hover_stack.get_top_item() != item:
		_hovered_element = item
		_hovered_element.mouse_entered()
		return true
	# Else, the tested item is currently on top of hover stack, then do nothing
	else:
		return false


## Unsets the hovered node.[br]
##[br]
## **Parameters**[br]
##[br]
## - item: the item that was unfocused (mouse_exited)
func unset_hovered_node(item: ESCItem):
	if item == null:
		return
	if _hovered_element == item:
		_hovered_element.do_mouse_exited()
		_hovered_element = null
		hotspot_focused = ""


# Background was hovered
func _on_hover_bg() -> void:
	escoria.main.current_scene.game.hovered_bg()

# The background was clicked with the LMB
#
# #### Parameters
#
# - position: Position of the click
func _on_left_click_on_bg(position: Vector2) -> void:
	if input_mode == INPUT_ALL: # and hotspot_focused.is_empty():
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
	if input_mode == INPUT_ALL: # and hotspot_focused.is_empty():
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
	if input_mode == INPUT_ALL and hotspot_focused.is_empty():
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
		if hover_stack.is_empty():
			hotspot_focused = ""
			escoria.main.current_scene.game.element_unfocused()
		else:
			hotspot_focused = hover_stack.get_top_item().global_id
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
		hover_stack.erase_item(item)
		escoria.main.current_scene.game.element_unfocused()
		return

	if object and not object.interactive:
		return
	if object and is_instance_valid(object.node) and object.node is ESCPlayer and not (object.node as ESCPlayer).selectable:
		hotspot_focused = ""
		return

	escoria.logger.info(
		self,
		"Item unfocused: %s" % hotspot_focused
	)

	if hover_stack.is_empty():
		hotspot_focused = ""
		escoria.main.current_scene.game.element_unfocused()
	else:
		hotspot_focused = hover_stack.get_top_item().global_id
		escoria.main.current_scene.game.element_focused(hotspot_focused)


## Function called when the item is set interactive, to re-trigger an input on
## underlying item.[br]
##[br]
## #### Parameters[br]
##[br]
## - item: The ESCCItem that was set non-interactive
func on_item_non_interactive(item: ESCItem) -> void:
	var object: ESCObject = escoria.object_manager.get_object(item.global_id)
	if object and not object.interactive:
		hover_stack.erase_item(item)
		escoria.main.current_scene.game.element_unfocused()

		if hover_stack.is_empty():
			return
		else:
			var new_item = hover_stack.get_top_item()
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
			if not hover_stack.is_empty():
				var next_item = hover_stack.pop_top_item()
				_on_mouse_left_clicked_item(next_item, event)
			else: # if no next object, consider this click as background click
				hotspot_focused = ""
				_on_left_click_on_bg(event.position)
			return

		# Clicked object can't be actioned and there is no other object behind
		# We consider this click as a background click
		if not escoria.action_manager.is_object_actionable(item.global_id) \
				and hover_stack.is_empty():
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
			if not hover_stack.is_empty():
				var next_item = hover_stack.pop_top_item()
				_on_mouse_left_double_clicked_item(next_item, event)
			else: # if no next object, consider this click as background click
				hotspot_focused = ""
				_on_double_left_click_on_bg(event.position)
			return

		# Clicked object can't be actioned and there is no other object behind
		# We consider this click as a background click
		if not escoria.action_manager.is_object_actionable(item.global_id) \
				and hover_stack.is_empty():
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

			if not hover_stack.is_empty():
				var next_item = hover_stack.pop_top_item()
				_on_mouse_right_clicked_item(next_item, event)
			return

		if not escoria.action_manager.is_object_actionable(item.global_id) \
				and hover_stack.is_empty():
			# Treat this as a background click now
			hotspot_focused = ""
			_on_right_click_on_bg(event.position)
			return

		var actual_item

		# We check if the clicked object is ESCPlayer and not selectable. If so
		# we consider we clicked through it.
		var object: ESCObject = escoria.object_manager.get_object(item.global_id)
		if object.node is ESCPlayer and not (object.node as ESCPlayer).selectable:
			actual_item = hover_stack.get_top_item()
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
					"No valid item found in the items stack. Action canceled."
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


## Hover Stack implementation.
class HoverStack:


	## Emitted when the content of the hover stack has changed
	signal hover_stack_changed

	## Emitted when the hover stack was emptied
	signal hover_stack_emptied


	## Array representing the hover stack
	var hover_stack: Array = []


	## Add the given item to the stack if not already in it.[br]
	##[br]
	## #### Parameters[br]
	## - item: the item to add to the hover stack
	func add_item(item):
		if item is ESCPlayer and not (item as ESCPlayer).selectable:
			return
		if not hover_stack.has(item):
			hover_stack.push_back(item)
			_sort()
			hover_stack_changed.emit()


	## Add the items contained in given list to the stack if not already in it.[br]
	##[br]
	## #### Parameters[br]
	## - items: the items list (array) to add to the hover stack
	func add_items(items: Array):
		for item in items:
			if escoria.action_manager.is_object_actionable(item.global_id):
				add_item(item)


	## Clean the hover stack
	func clean():
		for e in hover_stack:
			if e == null or !is_instance_valid(e):
				hover_stack.erase(e)
				hover_stack_changed.emit()


	## Pops the top element of the hover stack and returns it[br]
	##[br]
	## **Returns** The top element of the hover stack
	func pop_top_item():
		var ret = hover_stack.pop_back()
		if is_instance_valid(ret):
			hover_stack_changed.emit()
		return ret


	## Returns the top element of the hover stack[br]
	##[br]
	## **Returns** The top element of the hover stack
	func get_top_item():
		return hover_stack.back()


	## Remove the given item from the stack[br]
	##[br]
	## #### Parameters[br]
	## - item: the item to remove from the hover stack
	func erase_item(item):
		if hover_stack.has(item):
			hover_stack.erase(item)
			_sort()
			hover_stack_changed.emit()


	## Clear the stack of hovered items
	func clear():
		hover_stack = []
		hover_stack_emptied.emit()


	## Returns true if the hover stack is empty, else false[br]
	##[br]
	## **Returns** True if hover stack is empty, else false
	func is_empty() -> bool:
		return hover_stack.is_empty()


	# Sort the hover stack by items' z-index
	func _sort():
		hover_stack.sort_custom(Callable(HoverStackSorter, "sort_ascending_z_index"))


	## Returns true if the hover stack contains the given item[br]
	##[br]
	## #### Parameters[br]
	## - item: the item to search[br]
	##[br]
	## **Returns** True if hover stack contains given item, else false
	func has(item) -> bool:
		return hover_stack.has(item)


	## Returns the hover stack array[br]
	##[br]
	## **Returns** The hover stack array
	func get_all() -> Array:
		return hover_stack

	## Z Sorter class for hover stack
	class HoverStackSorter:
		static func sort_ascending_z_index(a, b):
			if a.z_index < b.z_index:
				return true
			return false
