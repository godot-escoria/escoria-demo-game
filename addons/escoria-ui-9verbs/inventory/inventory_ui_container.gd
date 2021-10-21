extends Control

"""
This script is totally user-defined. It does exactly what the user wants the 
inventory to look like. It only requires 4 functions to be defined:
	- is_empty() -> bool
	- get_items() -> Array
	- add_item(inventory_item: ESCInventoryItem)
	- remove_item(inventory_item: ESCInventoryItem)
The user is free to implement these methods the way s-he likes.
"""

var current_nodes_in_container = {}

func is_empty() -> bool:
	return get_child_count() > 0

func add_item(inventory_item: ESCInventoryItem):
	add_child(inventory_item)

func remove_item(inventory_item: ESCInventoryItem):
	remove_child(inventory_item)
	inventory_item.queue_free()
	
