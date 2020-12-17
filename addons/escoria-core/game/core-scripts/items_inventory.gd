extends Node


func get_inventory_item(item_id : String) -> ESCInventoryItem:
	for c in get_children():
		if c.global_id == item_id:
			if c.inventory_item_scene_file:
				return c.inventory_item_scene_file.instance()
	return null
