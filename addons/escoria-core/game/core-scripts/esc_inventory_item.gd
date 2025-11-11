## Container class containing basic information about an inventory item.
class_name ESCInventoryItem


## Global ID of the ESCItem that uses this ESCInventoryItem
var global_id: String = ""

## The texture for the item
var texture_normal: Texture2D = null

## The texture for the item when hovered
var texture_hovered: Texture2D = null


## Constructs the inventory item from an existing ESCItem.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_item|`ESCItem`|ESCItem instance to create the inventory item object from|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _init(p_item: ESCItem) -> void:
	global_id = p_item.global_id
	texture_normal = p_item._get_inventory_texture()
	texture_hovered = p_item._get_inventory_texture_hovered()
