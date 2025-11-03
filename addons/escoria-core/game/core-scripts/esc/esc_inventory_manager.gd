## A manager for inventory objects.
extends Resource
class_name ESCInventoryManager


## Checks whether the player has an inventory item.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |item|`String`|The inventory item's id.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `bool` value. (`bool`)
func inventory_has(item: String) -> bool:
	return escoria.globals_manager.has("i/%s" % item)


## Retrieves all inventory items.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `Array` value. (`Array`)
func items_in_inventory() -> Array:
	var items = []
	var filtered = escoria.globals_manager.filter("i/*")
	for glob in filtered.keys():
		if filtered[glob]:
			items.append(glob.rsplit("i/", false)[0])
	return items


## Removes an item from the player's inventory.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |item|`String`|The inventory item's id.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func remove_item(item: String) -> void:
	if not inventory_has(item):
		escoria.logger.error(
			self,
			"Error removing inventory item: " +
			"Trying to remove non-existent item %s." % item
		)
	else:
		escoria.globals_manager.set_global("i/%s" % item, false)


## Adds an item to the player's inventory.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |item|`String`|The inventory item's id.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func add_item(item: String) -> void:
	escoria.globals_manager.set_global("i/%s" % item, true)


## Saves the inventory in the specified savegame.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_savegame|`ESCSaveGame`|ESCSaveGame resource that holds all save data.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func save_game(p_savegame: ESCSaveGame) -> void:
	p_savegame.inventory = []
	for item in items_in_inventory():
		p_savegame.inventory.append(item)
