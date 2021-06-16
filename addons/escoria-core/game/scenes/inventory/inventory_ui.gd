extends Control
class_name ESCInventory

func get_class():
	return "ESCInventory"

"""
This script is set on the inventory UI scene's root node. 
The scene MUST contain the 2 following nodes:
	- one node named "ESCORIA_ALL_ITEMS" containing ALL ESCItems of the game. This is required
		to be able to get the ESCInventoryItem for a given ESCItem.
	- one Container node (under Control type) that will contain the inventory items. 
		It must be set in the "items_container" export variable.
"""


# Define the actual container node to add items as children of. Should be a Container.
export(NodePath) var inventory_ui_container
onready var all_items = $ESCORIA_ALL_ITEMS

var items_ids_in_inventory : Dictionary = {} # { item_id : TextureButton}

func _ready():
#	# For debugging scene only. These 2 lines should remain commented on normal run.
#	if !Engine.is_editor_hint():
#		return
	
	for item_id in escoria.inventory_manager.items_in_inventory():
		call_deferred("add_new_item_by_id", item_id)
		
	escoria.inventory = self
	
	if inventory_ui_container == null or inventory_ui_container.is_empty():
		escoria.logger.report_errors(self.get_path(), ["Items container is empty."])
		return
	for c in get_node(inventory_ui_container).get_items():
		items_ids_in_inventory[c.item_id] = c
#		c.connect("pressed", escoria.inputs_manager, "_on_inventory_item_pressed", [c.item_id])
		
	escoria.globals_manager.connect("global_changed", self, "_on_escoria_global_changed")


# add item to Inventory UI using its id set in its scene
func add_new_item_by_id(item_id : String) -> void:
	if item_id.begins_with("i/"):
		item_id = item_id.rsplit("i/", false)[0]
	if not items_ids_in_inventory.has(item_id):
		if not escoria.object_manager.has(item_id):
			var inventory_file = "%s/%s.tscn" % [
				ProjectSettings.get_setting(
					"escoria/ui/items_autoregister_path"
				).trim_suffix("/"),
				item_id
			]
			if ResourceLoader.exists(inventory_file):
				escoria.object_manager.register_object(
					ESCObject.new(
						item_id,
						ResourceLoader.load(inventory_file).instance()
					)
				)
			else:
				escoria.logger.report_errors(
					"inventory_ui.gd:add_new_item_by_id()",
					[
						"Item global id '%s' does not exist." % item_id, 
						"Check item's id in ESCORIA_ALL_ITEMS scene."
					]
				)
		var item_inventory_button = (
			escoria.object_manager.get_object(item_id).node as ESCItem
			).inventory_item.duplicate()
		items_ids_in_inventory[item_id] = item_inventory_button
		get_node(inventory_ui_container).add_item(item_inventory_button)
		
		# Add the item to inventory
		if not escoria.object_manager.has(item_id):
			escoria.object_manager.register_object(
				ESCObject.new(
					item_id, 
					item_inventory_button
				),
				true
			)
		item_inventory_button.visible = true
			
		item_inventory_button.connect("mouse_left_inventory_item", 
			escoria.inputs_manager, "_on_mouse_left_click_inventory_item")
		item_inventory_button.connect("mouse_double_left_inventory_item", 
			escoria.inputs_manager, "_on_mouse_double_left_click_inventory_item")
		item_inventory_button.connect("mouse_right_inventory_item", 
			escoria.inputs_manager, "_on_mouse_right_click_inventory_item")
		
		item_inventory_button.connect("inventory_item_focused", 
			escoria.inputs_manager, "_on_mouse_entered_inventory_item")
		item_inventory_button.connect("inventory_item_unfocused", 
			escoria.inputs_manager, "_on_mouse_exited_inventory_item")

# remove item fromInventory UI using its id set in its scene
func remove_item_by_id(item_id : String) -> void:
	if items_ids_in_inventory.has(item_id):
		var item_inventory_button = items_ids_in_inventory[item_id]
		
		item_inventory_button.disconnect("mouse_left_inventory_item", 
			escoria.inputs_manager, "_on_mouse_left_click_inventory_item")
		item_inventory_button.disconnect("mouse_double_left_inventory_item", 
			escoria.inputs_manager, "_on_mouse_double_left_click_inventory_item")
		item_inventory_button.disconnect("mouse_right_inventory_item", 
			escoria.inputs_manager, "_on_mouse_right_click_inventory_item")
		item_inventory_button.disconnect("inventory_item_focused", 
			escoria.inputs_manager, "_on_mouse_entered_inventory_item")
		item_inventory_button.disconnect("inventory_item_unfocused", 
			escoria.inputs_manager, "_on_mouse_exited_inventory_item")
		
		get_node(inventory_ui_container).remove_item(item_inventory_button)
		item_inventory_button.queue_free()
		items_ids_in_inventory.erase(item_id)

func _on_escoria_global_changed(global : String, old_value, new_value) -> void:
	if !global.begins_with("i/"):
		return 
	var item = global.rsplit("i/", false)
	if item.size() == 1:
		if new_value:
			add_new_item_by_id(item[0])
		else:
			remove_item_by_id(item[0])
	else:
		escoria.logger.report_errors("inventory_ui.gd:_on_escoria_global_changed()", ["Global must contain 1 item name.", "(received: " + global + ")"])
