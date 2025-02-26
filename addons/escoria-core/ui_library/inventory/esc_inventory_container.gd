# Inventory container handler that acts as a base for UIs inventory containers
extends Control
class_name ESCInventoryContainer

var item_focused: bool = false

# Get whether the inventory container currently is empty
# **Returns** Whether the container is empty or not
func is_empty() -> bool:
	return get_child_count() > 0

# Add a new item into the container and return the control generated for it
# so its events can be handled by the inputs manager
#
# #### Parameters
# - inventory_item: Item to add
# **Returns** The button generated for the item
func add_item(inventory_item: ESCInventoryItem) -> ESCInventoryButton:
	var button = ESCInventoryButton.new(inventory_item)
	button.inventory_item_focused.connect(_on_inventory_item_focused)
	button.inventory_item_unfocused.connect(_on_inventory_item_unfocused)
	add_child(button)
	return button


# Remove an item from the container
#
# #### Parameters
# - inventory_item: Item to remove
func remove_item(inventory_item: ESCInventoryItem):
	for c in get_children():
		if c is ESCInventoryButton and c.global_id == inventory_item.global_id:
			remove_child(c)
			c.queue_free()


# Return an Inventory button from the container, using an ESCInventoryItem
#
# #### Parameters
# - inventory_item: Inventory item to return the button node from
func get_inventory_button(inventory_item: ESCInventoryItem) -> ESCInventoryButton:
	var inventory_button = null
	for c in get_children():
		if c.global_id == inventory_item.global_id:
			inventory_button = c
			break
	return inventory_button


func _on_inventory_item_focused(item_id):
	item_focused = true


func _on_inventory_item_unfocused():
	item_focused = false
