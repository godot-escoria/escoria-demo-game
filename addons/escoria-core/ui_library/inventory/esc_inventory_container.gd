# Inventory container handler that acts as a base for UIs inventory containers
extends Control
class_name ESCInventoryContainer


# Get wether the inventory container currently is empty
# **Returns** Wether the container is empty or not
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
