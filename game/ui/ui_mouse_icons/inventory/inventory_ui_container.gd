extends Control

"""
This script is totally user-defined. It does exactly what the user wants the 
inventory to look like. It only requires 4 functions to be defined:
	- is_empty() -> bool
	- get_items() -> Array
	- add_item(inventory_item : ESCInventoryItem)
	- remove_item(inventory_item : ESCInventoryItem)
The user is free to implement these methods the way s-he likes.
"""

var current_nodes_in_container = {}

func is_empty() -> bool:
	return get_child_count() > 0

func get_items() -> Array:
	return current_nodes_in_container.keys()

func add_item(inventory_item : ESCInventoryItem):
	var center_container = CenterContainer.new()
	center_container.size_flags_horizontal = SIZE_EXPAND_FILL
	center_container.connect("mouse_entered", inventory_item, "_on_inventory_item_mouse_enter")
	center_container.connect("mouse_exited", inventory_item, "_on_inventory_item_mouse_exit")
	center_container.add_child(inventory_item)
	add_child(center_container)
	current_nodes_in_container[inventory_item] = center_container

func remove_item(inventory_item : ESCInventoryItem):
	var node_to_remove = current_nodes_in_container[inventory_item]
	current_nodes_in_container.erase(node_to_remove)
	node_to_remove.disconnect("mouse_entered", inventory_item, "_on_inventory_item_mouse_enter")
	node_to_remove.disconnect("mouse_exited", inventory_item, "_on_inventory_item_mouse_exit")
	remove_child(node_to_remove)
	node_to_remove.queue_free()
	
