@tool
extends Container

var source_image:Image
var image_stream_texture:CompressedTexture2D
var image_has_been_loaded:bool
var image_size:Vector2
var main_menu_requested:bool
var preview_size:Vector2

enum ItemType {BACKGROUND, INVENTORY}

const DEFAULT_ACTIONS: Array = ["look", "pick up", "open", "close", "use", "push", "pull", "talk"]

var current_item_type: ItemType = ItemType.BACKGROUND

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Capture the size of the window before we update its contents so we have
	# the absolute size before it gets scaled contents applied to it
	preview_size = %Preview.size
	_reset_ui()

# Resets the complete ui, clear all values, set item type mode to object
func _reset_ui() -> void:
	# Change visibility of components
	_setup_ui_to_itemtype(ItemType.BACKGROUND)
	# Resetting inputs
	%ItemName.text = "replace_me"
	%ItemGlobalID.text = ""
	%ImagePath.text = ""
	#Resetting other components
	%IsInteractiveCheckBox.button_pressed = true
	%InventoryPath.text = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
	%InventoryPathFileDialog.current_dir = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
	%Preview.texture = null
	#Resetting default actions
	%DefaultActionOption.clear()
	for option in DEFAULT_ACTIONS:
		%DefaultActionOption.add_item(option)
	%DefaultActionOption.selected = 0
	#Resetting variables
	image_size = Vector2.ZERO
	image_has_been_loaded = false
	main_menu_requested = false
	

# Sets the current item type variable and
# the component visibility based on the choosen itemtype
func _setup_ui_to_itemtype(new_type: ItemType) -> void:
	current_item_type = new_type
	_update_create_button_text()
	# First make all components invisible
	%InventoryHeading.visible = false
	%InventoryDescription.visible = false
	%InventoryPreview.visible = false
	%InventoryPath.visible = false
	%InventoryPathLabel.visible = false
	%ChangePathButton.visible = false
	%InventoryPath.visible = false
	%ObjectHeading.visible = false
	%ObjectDescription.visible = false
	%ObjectPreview.visible = false
	
	# Set visibility on relevant components
	if current_item_type == ItemType.BACKGROUND:
		%ObjectHeading.visible = true
		%ObjectDescription.visible = true
		%ObjectPreview.visible = true
	else:
		%InventoryHeading.visible = true
		%InventoryDescription.visible = true
		%InventoryPreview.visible = true
		%InventoryPath.visible = true
		%InventoryPathLabel.visible = true
		%ChangePathButton.visible = true
		%InventoryPath.visible = true

# Updates caption of create button text based on current item type
func _update_create_button_text() -> void:
	var new_text : String
	match current_item_type:
		ItemType.BACKGROUND:
			new_text = "Create Object"
		_:
			new_text = "Create Inventory"
	%CreateButton.text = new_text
	
func _toggle_button_pressed(clicked_type: ItemType) -> void:
	# Enable checkbox based on type
	%BackgroundObjectCheckBox.set_pressed_no_signal(clicked_type == ItemType.BACKGROUND)
	%InventoryItemCheckBox.set_pressed_no_signal(clicked_type == ItemType.INVENTORY)
	# If current type is equals to new type, do nothing
	if current_item_type == clicked_type:
		return
	_setup_ui_to_itemtype(clicked_type)
	
# Loads the selected image texture and displays it in the preview
func LoadImageFileDialog_file_selected(path: String) -> void:
	image_stream_texture = load(path)
	image_size = image_stream_texture.get_size()
	%Preview.texture = image_stream_texture

	%ImageSize.text = "(%s, %s)" % [image_size.x, image_size.y]

	%ImagePath.text = path
	image_has_been_loaded = true
	%InventoryPreview.visible = false
	%ObjectPreview.visible = false

func switch_to_main_menu() -> void:
	get_node("../Menu").visible = true
	get_node("../ItemCreator").visible = false

# Main function for creating a new item.
func create_item() -> void:
	var item = ESCItem.new()
	item.name = %ItemName.text
	item.global_id = %ItemGlobalID.text
	item.is_interactive = %IsInteractiveCheckBox.button_pressed
	item.tooltip_name = %ItemName.text

	var selected_index = %DefaultActionOption.selected
	item.default_action = %DefaultActionOption.get_item_text(selected_index)

	# Add Dialog Position to the background item
	var interact_position = ESCLocation.new()
	interact_position.name = "ESCLocation"
	interact_position.position.y = image_size.y * 2
	item.add_child(interact_position)

	# Add Collision shape to the background item
	var rectangle_shape = RectangleShape2D.new()
	var collision_shape = CollisionShape2D.new()

	collision_shape.shape = rectangle_shape
	collision_shape.shape.size = image_size / 2
	collision_shape.name = "CollisionShape"
	item.add_child(collision_shape)

	# Add sprite to the background item
	var item_sprite = Sprite2D.new()
	item_sprite.texture = %Preview.texture
	item_sprite.name = %ItemName.text
	item.add_child(item_sprite)

	if current_item_type == ItemType.BACKGROUND:
		place_new_item_in_scene_tree(item, collision_shape, interact_position, item_sprite)

		%CreateCompleteDialog.dialog_text = \
			"Background object %s created.\n\n" % item + \
			"Note that you can right-click the node in the\n" + \
			"scene tree and select \"Save branch as scene\"\n" + \
			"if you'd like to reuse this item."
		print("Background object %s created." % item)
		%CreateCompleteDialog.popup_centered()
	
	if current_item_type == ItemType.INVENTORY:
		# Make the item by default it's usable straight out of the inventory
		var new_pool_array: PackedStringArray = item.combine_when_selected_action_is_in
		new_pool_array.append("use")
		item.combine_when_selected_action_is_in = new_pool_array
		
		get_tree().edited_scene_root.add_child(item)
		## Make it so all the nodes can be seen in the scene tree
		collision_shape.set_owner(item)
		interact_position.set_owner(item)
		item_sprite.set_owner(item)

		item.set_owner(get_tree().edited_scene_root)
		# Export scene - create in inventory folder
		var packed_scene = PackedScene.new()

		packed_scene.pack(get_node(item.get_path()))
		
		var inventory_path = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
		# Flag suggestions from https://godotengine.org/qa/50437/how-to-turn-a-node-into-a-packedscene-via-gdscript
		var err = ResourceSaver.save(packed_scene, "%s/%s.tscn" % [inventory_path, %ItemName.text], \
			ResourceSaver.FLAG_CHANGE_PATH|ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
		if err:
			%ErrorDialog.dialog_text = \
				"Failed to save the item. Please make sure you can\n" + \
				"write to the destination folder: %s" % inventory_path
			%ErrorDialog.popup_centered()
			return
		else:
			item.queue_free()
			%CreateCompleteDialog.dialog_text = \
				"Inventory item %s/%s.tscn created." % [inventory_path, %ItemName.text]
			print("Inventory item %s/%s.tscn created." % [inventory_path, %ItemName.text])
			%CreateCompleteDialog.popup_centered()

# Create in scene tree
# Attach to currently selected node in scene tree
func place_new_item_in_scene_tree(item, collision_shape, interact_position, item_sprite) -> void:
	var current_node = EditorPlugin.new().get_editor_interface().get_selection().get_selected_nodes()[0]
	current_node.add_child(item)
	var owning_node = get_tree().edited_scene_root
	item.set_owner(owning_node)
	# Make it so all the nodes can be seen in the scene tree
	collision_shape.set_owner(owning_node)
	interact_position.set_owner(owning_node)
	item_sprite.set_owner(owning_node)

##### SIGNAL FUNCTIONS #############################

func _on_BackgroundObjectCheckBox_toggled(button_pressed: bool) -> void:
	_toggle_button_pressed(ItemType.BACKGROUND)

func _on_InventoryItemCheckBox_toggled(button_pressed: bool) -> void:
	_toggle_button_pressed(ItemType.INVENTORY)

func background_on_ItemName_text_changed(new_text: String) -> void:
	%ItemGlobalID.text = new_text
	
func load_button_pressed() -> void:
	%LoadImageFileDialog.current_dir = ""
	if current_item_type == ItemType.INVENTORY:
		%LoadImageFileDialog.current_dir = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
	%LoadImageFileDialog.popup_centered()
	
func Item_on_ClearButton_pressed() -> void:
	main_menu_requested = false
	%ConfirmationDialog.dialog_text = "WARNING!\n\n" + \
		"If you continue you will lose the current object."
	%ConfirmationDialog.popup_centered()
		
func Item_on_ExitButton_pressed() -> void:
	main_menu_requested = true
	%ConfirmationDialog.dialog_text = "WARNING!\n\n" + \
		"If you continue you will lose the current object."
	%ConfirmationDialog.popup_centered()

# Called, when confirmationdialog is been closed
func _on_ObjectConfirmationDialog_confirmed() -> void:
	if main_menu_requested == true:
		switch_to_main_menu()
	else:
		_reset_ui()
		
func _on_ChangePathButton_pressed():
	%InventoryPathFileDialog.popup_centered()

func _on_InventoryPathFileDialog_dir_selected(dir: String) -> void:
	ProjectSettings.set_setting("escoria/ui/inventory_items_path", dir)
	var property_info = {
		"name": "escoria/ui/inventory_items_path",
		"type": TYPE_STRING
	}
	ProjectSettings.add_property_info(property_info)
	%InventoryPath.text = dir
	
# Item was created and confirmed by user
func _on_CreateCompleteDialog_confirmed() -> void:
	_reset_ui()

# Called when user clicked the create button
# This function checks if all information are given
# and then calls the function for item creation
func _on_CreateButton_pressed() -> void:
	var inventory_path = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
	if not DirAccess.dir_exists_absolute(inventory_path):
		%ErrorDialog.dialog_text = \
			"Folder %s does not exist. Please create or change the destination" % inventory_path
		%ErrorDialog.popup_centered()
		return

	if not image_has_been_loaded:
		%ErrorDialog.dialog_text = \
			"No image has been loaded."
		%ErrorDialog.popup_centered()
		return

	if %ItemName.text == "replace_me":
		%ErrorDialog.dialog_text = \
			"Please change the object name."
		%ErrorDialog.popup_centered()
		return

	if current_item_type == ItemType.BACKGROUND:
		if not EditorPlugin.new().get_editor_interface().get_selection().get_selected_nodes():
			%ErrorDialog.dialog_text = \
				"Please select a node in the scene tree\nto attach the object to."
			%ErrorDialog.popup_centered()
			return
	create_item()
