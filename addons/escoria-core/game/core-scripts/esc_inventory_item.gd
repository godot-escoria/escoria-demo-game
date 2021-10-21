# Basic information about an inventory item
class_name ESCInventoryItem


# Global ID of the ESCItem that uses this ESCInventoryItem
var global_id: String = ""

# The texture for the item
var texture: Texture = null


func _init(p_item: ESCItem) -> void:
	global_id = p_item.global_id
	texture = p_item._get_inventory_texture()

