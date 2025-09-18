
## Inventory container handler that acts as a base for UIs inventory containers.
extends Control
class_name ESCInventoryContainer

## Whether any item in the container is currently focused.[br]
var item_focused: bool = false

## Returns whether the inventory container currently is empty.[br]
## [br]
## *Returns* Whether the container is empty or not.
func is_empty() -> bool:
	return get_child_count() > 0

## Adds a new item into the container and returns the control generated for it[br]
## so its events can be handled by the inputs manager.[br]
## [br]
## #### Parameters[br]
## [br]
## - inventory_item: Item to add.[br]
## [br]
## *Returns* The button generated for the item.
func add_item(inventory_item: ESCInventoryItem) -> ESCInventoryButton:
	var button = ESCInventoryButton.new(inventory_item)
	button.inventory_item_focused.connect(_on_inventory_item_focused)
	button.inventory_item_unfocused.connect(_on_inventory_item_unfocused)
	add_child(button)
	return button

## Removes an item from the container.[br]
## [br]
## #### Parameters[br]
## [br]
## - inventory_item: Item to remove.
func remove_item(inventory_item: ESCInventoryItem):
	for c in get_children():
		if c is ESCInventoryButton and c.global_id == inventory_item.global_id:
			remove_child(c)
			c.queue_free()


## Returns an Inventory button from the container, using an ESCInventoryItem.[br]
## [br]
## #### Parameters[br]
## [br]
## - inventory_item: Inventory item to return the button node from.[br]
## [br]
## *Returns* The inventory button node, or null if not found.
func get_inventory_button(inventory_item: ESCInventoryItem) -> ESCInventoryButton:
	var inventory_button = null
	for c in get_children():
		if c.global_id == inventory_item.global_id:
			inventory_button = c
			break
	return inventory_button


## Called when an inventory item is focused.[br]
## [br]
## #### Parameters[br]
## [br]
## - item_id: The global ID of the focused item.
func _on_inventory_item_focused(item_id):
	item_focused = true


## Called when an inventory item is unfocused.[br]
func _on_inventory_item_unfocused():
	item_focused = false
