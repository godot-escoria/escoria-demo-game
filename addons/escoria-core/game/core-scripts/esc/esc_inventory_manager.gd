## A manager for inventory objects.
extends Resource
class_name ESCInventoryManager


## Check if the player has an inventory item.[br]
## [br]
## #### Parameters[br]
## [br]
## - item: Inventory item id.[br]
## [br]
## **Returns** Whether the player has the inventory.
func inventory_has(item: String) -> bool:
	return escoria.globals_manager.has("i/%s" % item)


## Get all inventory items.[br]
## [br]
## **Returns** the items curerntly in the player's inventory.
func items_in_inventory() -> Array:
	var items = []
	var filtered = escoria.globals_manager.filter("i/*")
	for glob in filtered.keys():
		if filtered[glob]:
			items.append(glob.rsplit("i/", false)[0])
	return items

## Remove an item from the inventory.[br]
## [br]
## #### Parameters[br]
## [br]
## - item: Inventory item id.
func remove_item(item: String) -> void:
	if not inventory_has(item):
		escoria.logger.error(
			self,
			"Error removing inventory item: " +
			"Trying to remove non-existent item %s." % item
		)
	else:
		escoria.globals_manager.set_global("i/%s" % item, false)


## Add an item to the inventory.[br]
## [br]
## #### Parameters[br]
## [br]
## - item: Inventory item id.
func add_item(item: String) -> void:
	escoria.globals_manager.set_global("i/%s" % item, true)


## Save the inventory.[br]
## [br]
## #### Parameters[br]
## [br]
## - p_savegame: ESCSaveGame resource that holds all data of the save.
func save_game(p_savegame: ESCSaveGame) -> void:
	p_savegame.inventory = []
	for item in items_in_inventory():
		p_savegame.inventory.append(item)
