@tool
extends MarginContainer

var source_image:Image
var image_stream_texture:CompressedTexture2D
var image_has_been_loaded:bool
var image_size:Vector2
var main_menu_requested:bool
var inventory_mode:bool
var settings_modified:bool
var preview_size:Vector2

enum ItemType {BACKGROUNDOBJECT, INVENTORY}

const DEFAULT_ACTIONS: Array = ["look", "pick up", "open", "close", "use", "push", "pull", "talk"]

var current_item_type: ItemType = ItemType.BACKGROUNDOBJECT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Capture the size of the window before we update its contents so we have
	# the absolute size before it gets scaled contents applied to it
	preview_size = %Preview.size
	inventory_mode = not %BackgroundObjectCheckBox.pressed
	_reset_ui()

# Resets the complete ui, clear all values, set item type mode to object
func _reset_ui() -> void:
	# Change visibility of components
	_setup_ui_to_itemtype(ItemType.BACKGROUNDOBJECT)
	# Resetting inputs
	%ItemName.text = "replace_me"
	%ItemGlobalID.text = ""
	%ImagePath.text = ""
	#Resetting other components
	%IsInteractiveCheckBox.button_pressed = true
	%InventoryPath.text = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
	%FileDialog.current_dir = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
	#Resetting default actions
	%DefaultActionOption.clear()
	for option in DEFAULT_ACTIONS:
		%DefaultActionOption.add_item(option)
	%DefaultActionOption.selected = 0
	#Resetting variables
	image_size = Vector2.ZERO
	image_has_been_loaded = false
	main_menu_requested = false
	settings_modified = false
	

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
	%InventoryPathSpacer.visible = false
	%ChangePathButton.visible = false
	%InventoryPath.visible = false
	%ObjectHeading.visible = false
	%ObjectDescription.visible = false
	
	# Set visibility on relevant components
	if current_item_type == ItemType.BACKGROUNDOBJECT:
		%ObjectHeading.visible = true
		%ObjectDescription.visible = true
		%ObjectPreview.visible = true
	else:
		%InventoryHeading.visible = true
		%InventoryDescription.visible = true
		%InventoryPreview.visible = true
		%InventoryPath.visible = true
		%InventoryPathLabel.visible = true
		%InventoryPathSpacer.visible = true
		%ChangePathButton.visible = true
		%InventoryPath.visible = true

# Updates caption of create button text based on current item type
func _update_create_button_text() -> void:
	var new_text : String
	match current_item_type:
		ItemType.BACKGROUNDOBJECT:
			new_text = "Create Object"
		_:
			new_text = "Create Inventory"
	%CreateButton.text = new_text
	
func _on_BackgroundObjectCheckBox_toggled(button_pressed: bool) -> void:
	_toggle_button_pressed(ItemType.BACKGROUNDOBJECT)

func _on_InventoryItemCheckBox_toggled(button_pressed: bool) -> void:
	_toggle_button_pressed(ItemType.INVENTORY)
	
func _toggle_button_pressed(clicked_type: ItemType) -> void:
	# Enable checkbox based on type
	%BackgroundObjectCheckBox.set_pressed_no_signal(clicked_type == ItemType.BACKGROUNDOBJECT)
	%InventoryItemCheckBox.set_pressed_no_signal(clicked_type == ItemType.INVENTORY)
	# If current type is equals to new type, do nothing
	if current_item_type == clicked_type:
		return
	_setup_ui_to_itemtype(clicked_type)

##### OLD FUNCTIONS ################################l

#func item_creator_reset() -> void:
	#%ItemName.text = "replace_me"
	#%ItemGlobalID.text = ""
	#%ImagePath.text = ""
	#%IsInteractiveCheckBox.button_pressed = true
#
	#if %DefaultActionOption.get_item_count() > 0:
		#%DefaultActionOption.clear()
		## Todo List is never been filled??
		#for option_list in ["look", "pick up", "open", "close", "use", "push", "pull", "talk"]:
			#%DefaultActionOption.add_item(option_list)
#
	#%DefaultActionOption.selected = 0
	#image_size = Vector2.ZERO
	#image_has_been_loaded = false
	#main_menu_requested = false
	#settings_modified = false
	#%Preview.texture = null
#
	#if inventory_mode:
		#%InventoryPath.text = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
		#%CreateButton.text = "Create Inventory"
		#%InventoryPreview.visible = true
		#%ObjectPreview.visible = false
#
		#for loop in [%InventoryPath, %InventoryPathLabel, %InventoryPathSpacer, \
			#%ChangePathButton]:
			#get_node(loop).visible = true
	#else:
		#%CreateButton.text = "Create Object"
		#%InventoryPreview.visible = false
		#%ObjectPreview.visible = true
		#for loop in [%InventoryPath, %InventoryPathLabel, %InventoryPathSpacer, \
			#%ChangePathButton]:
			#get_node(loop).visible = false
#
	#for loop in [%ObjectHeading, %ObjectDescription]:
		#get_node(loop).visible = not inventory_mode
#
	#for loop in [%InventoryHeading, %InventoryDescription, %InventoryPath]:
		#get_node(loop).visible = inventory_mode
	#%FileDialog.current_dir = ProjectSettings.get_setting("escoria/ui/inventory_items_path")

func resize_image() -> void:
	# Calculate the scale to make the preview as big as possible in the preview window depending on
	# the height to width ratio of the frame
	image_size = image_stream_texture.get_size()
	var preview_scale = Vector2.ONE
	preview_scale.x =  preview_size.x / image_size.x
	preview_scale.y =  preview_size.y / image_size.y

	if preview_scale.y > preview_scale.x:
		%Preview.scale = Vector2(preview_scale.x, preview_scale.x)
	else:
		%Preview.scale = Vector2(preview_scale.y, preview_scale.y)

func background_on_ItemName_text_changed(new_text: String) -> void:
	%ItemGlobalID.text = new_text
	settings_modified = true


func load_button_pressed() -> void:
	%LoadObjectFileDialog.popup_centered()


func LoadObjectFileDialog_file_selected(path: String) -> void:
	image_stream_texture = load(path)

	%Preview.texture = image_stream_texture

	resize_image()

	%ImageSize.text = "(%s, %s)" % [image_size.x, image_size.y]

	%ImagePath.text = path
	image_has_been_loaded = true
	settings_modified = true
	%InventoryPreview.visible = false
	%ObjectPreview.visible = false


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

	if inventory_mode == false:
		if not EditorPlugin.new().get_editor_interface().get_selection().get_selected_nodes():
			%ErrorDialog.dialog_text = \
				"Please select a node in the scene tree\nto attach the object to."
			%ErrorDialog.popup_centered()
			return

	var item = ESCItem.new()
	item.name = %ItemName.text
	item.global_id = %ItemGlobalID.text
	item.is_interactive = %IsInteractiveCheckBox.pressed
	item.tooltip_name = %ItemName.text

	var selected_index = %DefaultActionOption.selected
	item.default_action = %DefaultActionOption.get_item_text(selected_index)

	# Make the item by default it's usable straight out of the inventory
	if inventory_mode == true:
		var new_pool_array: PackedStringArray = item.combine_when_selected_action_is_in
		new_pool_array.append("use")
		item.combine_when_selected_action_is_in = new_pool_array

	# Add Dialog Position to the background item
	var interact_position = ESCLocation.new()
	interact_position.name = "interact_position"
	interact_position.position.y = image_size.y * 2
	item.add_child(interact_position)

	# Add Collision shape to the background item
	var rectangle_shape = RectangleShape2D.new()
	var collision_shape = CollisionShape2D.new()

	collision_shape.shape = rectangle_shape
	collision_shape.shape.extents = image_size / 2
	item.add_child(collision_shape)

	# Add sprite to the background item
	var item_sprite = Sprite2D.new()
	item_sprite.texture = %Preview.texture
	item.add_child(item_sprite)

	if not inventory_mode:
		# Create in scene tree
		# Attach to currently selected node in scene tree
		var current_node = EditorPlugin.new().get_editor_interface().get_selection().get_selected_nodes()[0]
		current_node.add_child(item)
		var owning_node = get_tree().edited_scene_root
		item.set_owner(owning_node)
		# Make it so all the nodes can be seen in the scene tree
		collision_shape.set_owner(owning_node)
		interact_position.set_owner(owning_node)
		item_sprite.set_owner(owning_node)

		get_node("Windows/CreateCompleteDialog").dialog_text = \
			"Background object %s created.\n\n" % item + \
			"Note that you can right-click the node in the\n" + \
			"scene tree and select \"Save branch as scene\"\n" + \
			"if you'd like to reuse this item."
		print("Background object %s created." % item)
		get_node("Windows/CreateCompleteDialog").popup_centered()
	else:
		get_tree().edited_scene_root.add_child(item)
		# Make it so all the nodes can be seen in the scene tree
		collision_shape.set_owner(item)
		interact_position.set_owner(item)
		item_sprite.set_owner(item)

		item.set_owner(get_tree().edited_scene_root)
		# Export scene - create in inventory folder
		var packed_scene = PackedScene.new()

		packed_scene.pack(get_tree().edited_scene_root.get_node(item.name))

		# Flag suggestions from https://godotengine.org/qa/50437/how-to-turn-a-node-into-a-packedscene-via-gdscript
		var err = ResourceSaver.save(packed_scene, "%s/%s.tscn" % [inventory_path, %ItemName.text], \
			ResourceSaver.FLAG_CHANGE_PATH|ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
		if err:
			%ErrorDialog.dialog_text = \
				"Failed to save the item. Please make sure you can\n" + \
				"write to the destination folder" % inventory_path
			%ErrorDialog.popup_centered()
			return
		else:
			item.queue_free()
			get_tree().edited_scene_root.get_node(item.name).queue_free()
			get_node("Windows/CreateCompleteDialog").dialog_text = \
				"Inventory item %s/%s.tscn created." % [inventory_path, %ItemName.text]
			print("Inventory item %s/%s.tscn created." % [inventory_path, %ItemName.text])
			get_node("Windows/CreateCompleteDialog").popup_centered()


func Item_on_ClearButton_pressed() -> void:
	if settings_modified == true:
		main_menu_requested = false
		%ConfirmationDialog.dialog_text = "WARNING!\n\n" + \
			"If you continue you will lose the current object."
		%ConfirmationDialog.popup_centered()


func _on_ObjectConfirmationDialog_confirmed() -> void:
	if main_menu_requested == true:
		switch_to_main_menu()
	#else:
		#item_creator_reset()


func Item_on_ExitButton_pressed() -> void:
	if settings_modified == true:
		main_menu_requested = true
		%ConfirmationDialog.dialog_text = "WARNING!\n\n" + \
			"If you continue you will lose the current object."
		%ConfirmationDialog.popup_centered()
	else:
		switch_to_main_menu()


func switch_to_main_menu() -> void:
	get_node("../Menu").visible = true
	get_node("../ItemCreator").visible = false


func _on_StartsInteractiveCheckBox_pressed() -> void:
	settings_modified = true


func _on_ItemGlobalID_text_changed(_new_text: String) -> void:
	settings_modified = true


func _on_DefaultActionOption_item_selected(_index: int) -> void:
	settings_modified = true


func _on_CreateCompleteDialog_confirmed() -> void:
	pass
	#item_creator_reset()


#func _on_BackgroundObjectCheckBox_toggled(button_pressed: bool) -> void:
	#if button_pressed == false:
		#$VBoxContainer/Control/CenterContainer/HBoxContainer/InventoryItemCheckBox.set_pressed_no_signal(true)
		#inventory_mode = true
	#else:
		#$VBoxContainer/Control/CenterContainer/HBoxContainer/InventoryItemCheckBox.set_pressed_no_signal(false)
		#inventory_mode = false
#
	#item_creator_reset()


#func _on_InventoryItemCheckBox_toggled(button_pressed: bool) -> void:
	#if button_pressed == false:
		#$VBoxContainer/Control/CenterContainer/HBoxContainer/BackgroundObjectCheckBox.set_pressed_no_signal(true)
		#inventory_mode = false
	#else:
		#$VBoxContainer/Control/CenterContainer/HBoxContainer/BackgroundObjectCheckBox.set_pressed_no_signal(false)
		#inventory_mode = true
#
	#item_creator_reset()


func _on_ChangePathButton_pressed():
	%FileDialog.popup_centered()


func _on_FileDialog_dir_selected(dir: String) -> void:
	ProjectSettings.set_setting("escoria/ui/inventory_items_path", dir)
	var property_info = {
		"name": "escoria/ui/inventory_items_path",
		"type": TYPE_STRING
	}
	ProjectSettings.add_property_info(property_info)
	%InventoryPath.text = dir
