# Manages the inventory on the GUI connected to the inventory_ui_container
# variable
extends Control
class_name ESCInventory


# Define the actual container node to add items as children of.
# Should be a Container.
@export var inventory_ui_container: NodePath


# A registry of inventory ESCInventoryItem nodes
var items_ids_in_inventory: Dictionary = {}


# Fill the items the player has from the start, do sanity checks and
# listen when a global has changed
func _ready():
	if inventory_ui_container == null or inventory_ui_container.is_empty():
		escoria.logger.error(
			self,
			"Inventory items container is empty."
		)
		return

	for item_id in escoria.inventory_manager.items_in_inventory():
		call_deferred("add_new_item_by_id", item_id)

	escoria.inventory = self
	escoria.globals_manager.global_changed.connect(_on_escoria_global_changed)


# add item to Inventory UI using its id set in its scene
func add_new_item_by_id(item_id: String) -> void:
	if item_id.begins_with("i/"):
		item_id = item_id.rsplit("i/", false)[0]
	if not items_ids_in_inventory.has(item_id):
		if not escoria.object_manager.has(item_id) or not is_instance_valid( \
				escoria.object_manager.get_object(item_id).node):
			var inventory_file = "%s/%s.tscn" % [
				ESCProjectSettingsManager.get_setting(
					ESCProjectSettingsManager.INVENTORY_ITEMS_PATH
				).trim_suffix("/"),
				item_id
			]
			if ResourceLoader.exists(inventory_file):
				escoria.object_manager.register_object(
					ESCObject.new(
						item_id,
						ResourceLoader.load(inventory_file).instantiate()
					),
					null,
					true
				)
			else:
				escoria.logger.error(
					self,
					(
						"Item global id '%s' is not registered because the item's scene file was not found.\n"
						+ "Attempted scene file path: %s.\n"
						+ "Please ensure that the '%s' project setting points at **your inventory items folder** (current is: \"%s\")."
					)
						% [
							item_id,
							inventory_file,
							ESCProjectSettingsManager.INVENTORY_ITEMS_PATH,
							ESCProjectSettingsManager.get_setting(
								ESCProjectSettingsManager.INVENTORY_ITEMS_PATH
							)
						]
				)

		var inventory_item = escoria.di.esc_inventory_item(
			escoria.object_manager.get_object(item_id).node
		)
		var inventory_item_button = get_node(
			inventory_ui_container
		).add_item(inventory_item)

		items_ids_in_inventory[item_id] = inventory_item

		if not escoria.object_manager.has(item_id):
			escoria.object_manager.register_object(
				ESCObject.new(
					item_id,
					inventory_item_button
				),
				null,
				true
			)

		escoria.inputs_manager.register_inventory_item(inventory_item_button)


# remove item fromInventory UI using its id set in its scene
func remove_item_by_id(item_id: String) -> void:
	if items_ids_in_inventory.has(item_id):
		var item_inventory = items_ids_in_inventory[item_id]
		var item_inventory_button = get_node(
			inventory_ui_container
		).get_inventory_button(item_inventory)

		if item_inventory_button.mouse_left_inventory_item.is_connected(
			escoria.inputs_manager._on_mouse_left_click_inventory_item
		):
			item_inventory_button.mouse_left_inventory_item.disconnect(
				escoria.inputs_manager._on_mouse_left_click_inventory_item
			)
		if item_inventory_button.mouse_double_left_inventory_item.is_connected(
			escoria.inputs_manager._on_mouse_double_left_click_inventory_item
		):
			item_inventory_button.mouse_double_left_inventory_item.disconnect(
				escoria.inputs_manager._on_mouse_double_left_click_inventory_item
			)
		if item_inventory_button.mouse_right_inventory_item.is_connected(
			escoria.inputs_manager._on_mouse_right_click_inventory_item
		):
			item_inventory_button.mouse_right_inventory_item.disconnect(
				escoria.inputs_manager._on_mouse_right_click_inventory_item
			)
		if item_inventory_button.inventory_item_focused.is_connected(
			escoria.inputs_manager._on_mouse_entered_inventory_item
		):
			item_inventory_button.inventory_item_focused.disconnect(
				escoria.inputs_manager._on_mouse_entered_inventory_item
			)
		if item_inventory_button.inventory_item_unfocused.is_connected(
			escoria.inputs_manager._on_mouse_exited_inventory_item
		):
			item_inventory_button.inventory_item_unfocused.disconnect(
				escoria.inputs_manager._on_mouse_exited_inventory_item
			)

		get_node(inventory_ui_container).remove_item(item_inventory)
		items_ids_in_inventory.erase(item_id)


# React to changes to inventory globals adding items or removing them
func _on_escoria_global_changed(global: String, old_value, new_value) -> void:
	if !global.begins_with("i/"):
		return
	var item = global.rsplit("i/", false)
	if item.size() == 1:
		if new_value:
			add_new_item_by_id(item[0])
		else:
			remove_item_by_id(item[0])
	else:
		escoria.logger.error(
			self,
			"Global must contain only one item name (received: %s)." % global
		)


# Clear the inventory UI of all its items.
func clear() -> void:
	var items_in_inventory_keys: Array = items_ids_in_inventory.keys()
	for item_id in items_in_inventory_keys:
		remove_item_by_id(item_id)
