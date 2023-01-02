tool
extends MarginContainer


const ITEM_NAME_NODE      = "VBoxContainer/Content/GridContainer/ItemName"
const GLOBAL_ID_NODE      = "VBoxContainer/Content/GridContainer/ItemGlobalID"
const INTERACTIVE_NODE    = "VBoxContainer/Content/GridContainer/StartsInteractiveCheckBox"
const ACTION_NODE         = "VBoxContainer/Content/GridContainer/DefaultActionOption"
const PREVIEW_NODE        = "VBoxContainer/Content/GridContainer/Preview/Preview"
const IMAGE_SIZE_NODE     = "VBoxContainer/Content/GridContainer/ImageSize"
const IMAGE_PATH_NODE     = "VBoxContainer/Content/GridContainer/ImagePath"
const LOAD_NODE           = "LoadObjectGraphic/LoadObjectFileDialog"
const CONFIRM_NODE        = "Windows/ConfirmationDialog"
const OBJECT_HEADING_NODE = "VBoxContainer/HelperHeading/CenterContainer/ObjectHeading"
const OBJECT_DESC_NODE    = "VBoxContainer/Description/ObjectDescription"
const INVENTORY_HEADING_NODE = "VBoxContainer/HelperHeading/CenterContainer/InventoryHeading"
const INVENTORY_DESC_NODE = "VBoxContainer/Description/InventoryDescription"
const INVENTORY_PATH_NODE = "VBoxContainer/Content/GridContainer/InventoryPath"
const INVENTORY_PATH_LABEL_NODE = "VBoxContainer/Content/GridContainer/InventoryPathLabel"
const INVENTORY_PATH_SPACER_NODE = "VBoxContainer/Content/GridContainer/BlankItem7"
const CREATE_BUTTON_NODE  = "VBoxContainer/Buttons/CenterContainer/HBoxContainer/CreateButton"
const ERROR_WINDOW_NODE   = "Windows/ErrorDialog"
const INVENTORY_PREV_NODE = "VBoxContainer/Content/GridContainer/Preview/InventoryPreview"
const OBJECT_PREV_NODE    = "VBoxContainer/Content/GridContainer/Preview/ObjectPreview"
const BACKGROUND_OBJ_NODE = "VBoxContainer/Control/CenterContainer/HBoxContainer/BackgroundObjectCheckBox"
const CHANGE_PATH_NODE    = "VBoxContainer/Content/GridContainer/ChangePathButton"

var source_image:Image
var image_stream_texture:StreamTexture
var image_has_been_loaded:bool
var image_size:Vector2
var main_menu_requested:bool
var inventory_mode:bool
var settings_modified:bool
var preview_size:Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Capture the size of the window before we update its contents so we have
	# the absolute size before it gets scaled contents applied to it
	preview_size = get_node(PREVIEW_NODE).rect_size
	inventory_mode = not get_node(BACKGROUND_OBJ_NODE).pressed
	item_creator_reset()


func item_creator_reset() -> void:
	get_node(ITEM_NAME_NODE).text = "replace_me"
	get_node(GLOBAL_ID_NODE).text = ""
	get_node(IMAGE_PATH_NODE).text = ""
	get_node(INTERACTIVE_NODE).pressed = true

	if get_node(ACTION_NODE).get_item_count() > 0:
		get_node(ACTION_NODE).clear()

		for option_list in ["look", "pick up", "open", "close", "use", "push", "pull", "talk"]:
			get_node(ACTION_NODE).add_item(option_list)

	get_node(ACTION_NODE).selected = 0
	image_size = Vector2.ZERO
	image_has_been_loaded = false
	main_menu_requested = false
	settings_modified = false
	get_node(PREVIEW_NODE).texture = null

	if inventory_mode:
		get_node(INVENTORY_PATH_NODE).text = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
		get_node(CREATE_BUTTON_NODE).text = "Create Inventory"
		get_node(INVENTORY_PREV_NODE).visible = true
		get_node(OBJECT_PREV_NODE).visible = false

		for loop in [INVENTORY_PATH_NODE, INVENTORY_PATH_LABEL_NODE, INVENTORY_PATH_SPACER_NODE, \
			CHANGE_PATH_NODE]:
			get_node(loop).visible = true
	else:
		get_node(CREATE_BUTTON_NODE).text = "Create Object"
		get_node(INVENTORY_PREV_NODE).visible = false
		get_node(OBJECT_PREV_NODE).visible = true
		for loop in [INVENTORY_PATH_NODE, INVENTORY_PATH_LABEL_NODE, INVENTORY_PATH_SPACER_NODE, \
			CHANGE_PATH_NODE]:
			get_node(loop).visible = false

	for loop in [OBJECT_HEADING_NODE, OBJECT_DESC_NODE]:
		get_node(loop).visible = not inventory_mode

	for loop in [INVENTORY_HEADING_NODE, INVENTORY_DESC_NODE, INVENTORY_PATH_NODE]:
		get_node(loop).visible = inventory_mode
	$Windows/FileDialog.current_dir = ProjectSettings.get_setting("escoria/ui/inventory_items_path")

func resize_image() -> void:
	# Calculate the scale to make the preview as big as possible in the preview window depending on
	# the height to width ratio of the frame
	image_size = image_stream_texture.get_size()
	var preview_scale = Vector2.ONE
	preview_scale.x =  preview_size.x / image_size.x
	preview_scale.y =  preview_size.y / image_size.y

	if preview_scale.y > preview_scale.x:
		get_node(PREVIEW_NODE).rect_scale = Vector2(preview_scale.x, preview_scale.x)
	else:
		get_node(PREVIEW_NODE).rect_scale = Vector2(preview_scale.y, preview_scale.y)

func background_on_ItemName_text_changed(new_text: String) -> void:
	get_node(GLOBAL_ID_NODE).text = new_text
	settings_modified = true


func load_button_pressed() -> void:
	get_node(LOAD_NODE).popup_centered()


func LoadObjectFileDialog_file_selected(path: String) -> void:
	image_stream_texture = load(path)

	get_node(PREVIEW_NODE).texture = image_stream_texture

	resize_image()

	get_node(IMAGE_SIZE_NODE).text = "(%s, %s)" % [image_size.x, image_size.y]

	get_node(IMAGE_PATH_NODE).text = path
	image_has_been_loaded = true
	settings_modified = true
	get_node(INVENTORY_PREV_NODE).visible = false
	get_node(OBJECT_PREV_NODE).visible = false


func _on_CreateButton_pressed() -> void:
	var inventory_path = ProjectSettings.get_setting("escoria/ui/inventory_items_path")
	var directory_test = Directory.new();
	if not directory_test.dir_exists(inventory_path):
		get_node(ERROR_WINDOW_NODE).dialog_text = \
			"Folder %s does not exist. Please create or change the destination" % inventory_path
		get_node(ERROR_WINDOW_NODE).popup_centered()
		return

	if not image_has_been_loaded:
		get_node(ERROR_WINDOW_NODE).dialog_text = \
			"No image has been loaded."
		get_node(ERROR_WINDOW_NODE).popup_centered()
		return

	if get_node(ITEM_NAME_NODE).text == "replace_me":
		get_node(ERROR_WINDOW_NODE).dialog_text = \
			"Please change the object name."
		get_node(ERROR_WINDOW_NODE).popup_centered()
		return

	if inventory_mode == false:
		if not EditorPlugin.new().get_editor_interface().get_selection().get_selected_nodes():
			get_node(ERROR_WINDOW_NODE).dialog_text = \
				"Please select a node in the scene tree\nto attach the object to."
			get_node(ERROR_WINDOW_NODE).popup_centered()
			return

	var item = ESCItem.new()
	item.name = get_node(ITEM_NAME_NODE).text
	item.global_id = get_node(GLOBAL_ID_NODE).text
	item.is_interactive = get_node(INTERACTIVE_NODE).pressed
	item.tooltip_name = get_node(ITEM_NAME_NODE).text
	
	var selected_index = get_node(ACTION_NODE).selected
	item.default_action = get_node(ACTION_NODE).get_item_text(selected_index)

	# Make the item by default it's usable straight out of the inventory
	if inventory_mode == true:
		var new_pool_array: PoolStringArray = item.combine_when_selected_action_is_in
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
	var item_sprite = Sprite.new()
	item_sprite.texture = get_node(PREVIEW_NODE).texture
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
		var err = ResourceSaver.save("%s/%s.tscn" % [inventory_path, get_node(ITEM_NAME_NODE).text], packed_scene, \
			ResourceSaver.FLAG_CHANGE_PATH|ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
		if err:
			get_node(ERROR_WINDOW_NODE).dialog_text = \
				"Failed to save the item. Please make sure you can\n" + \
				"write to the destination folder" % inventory_path
			get_node(ERROR_WINDOW_NODE).popup_centered()
			return
		else:
			item.queue_free()
			get_tree().edited_scene_root.get_node(item.name).queue_free()
			get_node("Windows/CreateCompleteDialog").dialog_text = \
				"Inventory item %s/%s.tscn created." % [inventory_path, get_node(ITEM_NAME_NODE).text]
			print("Inventory item %s/%s.tscn created." % [inventory_path, get_node(ITEM_NAME_NODE).text])
			get_node("Windows/CreateCompleteDialog").popup_centered()


func Item_on_ClearButton_pressed() -> void:
	if settings_modified == true:
		main_menu_requested = false
		get_node(CONFIRM_NODE).dialog_text = "WARNING!\n\n" + \
			"If you continue you will lose the current object."
		get_node(CONFIRM_NODE).popup_centered()


func _on_ObjectConfirmationDialog_confirmed() -> void:
	if main_menu_requested == true:
		switch_to_main_menu()
	else:
		item_creator_reset()


func Item_on_ExitButton_pressed() -> void:
	if settings_modified == true:
		main_menu_requested = true
		get_node(CONFIRM_NODE).dialog_text = "WARNING!\n\n" + \
			"If you continue you will lose the current object."
		get_node(CONFIRM_NODE).popup_centered()
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
	item_creator_reset()


func _on_BackgroundObjectCheckBox_toggled(button_pressed: bool) -> void:
	if button_pressed == false:
		$VBoxContainer/Control/CenterContainer/HBoxContainer/InventoryItemCheckBox.set_pressed_no_signal(true)
		inventory_mode = true
	else:
		$VBoxContainer/Control/CenterContainer/HBoxContainer/InventoryItemCheckBox.set_pressed_no_signal(false)
		inventory_mode = false

	item_creator_reset()


func _on_InventoryItemCheckBox_toggled(button_pressed: bool) -> void:
	if button_pressed == false:
		$VBoxContainer/Control/CenterContainer/HBoxContainer/BackgroundObjectCheckBox.set_pressed_no_signal(true)
		inventory_mode = false
	else:
		$VBoxContainer/Control/CenterContainer/HBoxContainer/BackgroundObjectCheckBox.set_pressed_no_signal(false)
		inventory_mode = true

	item_creator_reset()


func _on_ChangePathButton_pressed():
	$"Windows/FileDialog".popup_centered()


func _on_FileDialog_dir_selected(dir: String) -> void:
	ProjectSettings.set_setting("escoria/ui/inventory_items_path", dir)
	var property_info = {
		"name": "escoria/ui/inventory_items_path",
		"type": TYPE_STRING
	}
	ProjectSettings.add_property_info(property_info)
	get_node(INVENTORY_PATH_NODE).text = dir
