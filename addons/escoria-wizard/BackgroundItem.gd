tool
extends MarginContainer

var source_image:Image
var image_stream_texture:StreamTexture
var image_has_been_loaded:bool
var image_size:Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background_item_reset()


func background_item_reset() -> void:
	$Content/GridContainer/ItemName.text = "replace_me"
	$Content/GridContainer/ItemGlobalID.text = ""
	$Content/GridContainer/StartsInnteractiveCheckBox.pressed = true
	if $Content/GridContainer/DefaultActionOption.get_item_count() > 0:
		$Content/GridContainer/DefaultActionOption.clear()
		for option_list in ["look", "pick up", "open", "close", "use", "push", "pull", "talk"]:
			$Content/GridContainer/DefaultActionOption.add_item(option_list)
	$Content/GridContainer/DefaultActionOption.selected = 0
	image_size = Vector2.ZERO
	image_has_been_loaded = false


func background_on_ItemName_text_changed(new_text: String) -> void:
	$Content/GridContainer/ItemGlobalID.text = new_text


func load_button_pressed() -> void:
	$LoadObjectGraphic/LoadObjectFileDialog.popup()


func LoadObjectFileDialog_file_selected(path: String) -> void:
	image_stream_texture = load(path)

	$Content/GridContainer/Preview/Preview.texture = image_stream_texture

	var preview_size = $Content/GridContainer/Preview/Preview.rect_size

	# Calculate the scale to make the preview as big as possible in the preview window depending on
	# the height to width ratio of the frame
	image_size = image_stream_texture.get_size()
	var preview_scale = Vector2.ONE
	preview_scale.x =  preview_size.x / image_size.x
	preview_scale.y =  preview_size.y / image_size.y

	if preview_scale.y > preview_scale.x:
		$Content/GridContainer/Preview/Preview.rect_scale = Vector2(preview_scale.x, preview_scale.x)
	else:
		$Content/GridContainer/Preview/Preview.rect_scale = Vector2(preview_scale.y, preview_scale.y)

	$Content/GridContainer/ImageSize.text = "(%s, %s)" % [image_size.x, image_size.y]

	$Content/GridContainer/ImagePath.text = path
	image_has_been_loaded = true



func _on_CreateButton_pressed() -> void:
	var err_window = "../InformationWindows/generic_error_window"
	if ! image_has_been_loaded:
		get_node(err_window).dialog_text = \
			"No image has been loaded."
		get_node(err_window).popup()
		return
	if $Content/GridContainer/ItemName.text == "replace_me":
		get_node(err_window).dialog_text = \
			"Please change the object name."
		get_node(err_window).popup()
		return

	var item = ESCItem.new()
	item.name = $Content/GridContainer/ItemName.text
	item.global_id = $Content/GridContainer/ItemGlobalID.text
	item.is_interactive = $Content/GridContainer/StartsInnteractiveCheckBox.pressed
	item.tooltip_name = $Content/GridContainer/ItemName.text

	var selected_index = $Content/GridContainer/DefaultActionOption.selected
	item.default_action = $Content/GridContainer/DefaultActionOption.get_item_text(selected_index)

	# Add sprite to the background item
	var item_sprite = Sprite.new()
	item_sprite.texture = $Content/GridContainer/Preview/Preview.texture
	item.add_child(item_sprite)

	# Add Dialog Position to the background item
	var interact_position = ESCLocation.new()
	interact_position.name = "interact_position"
	interact_position.position.y = image_size.y * 2
	print("A")
	item.add_child(interact_position)

	# Add Collision shape to the background item
	var rectangle_shape = RectangleShape2D.new()
	var collision_shape = CollisionShape2D.new()

	collision_shape.shape = rectangle_shape
	collision_shape.shape.extents = image_size / 2
	print("B")
	item.add_child(collision_shape)
	print("c")
	# Make it so all the nodes can be seen in the scene tree
	interact_position.set_owner(item)
	print("d")
	collision_shape.set_owner(item)
	print("e")

	item_sprite.set_owner(item)

	print("f")

#	get_tree().edited_scene_root.add_child(item)
#	item.set_owner(get_tree().edited_scene_root)


	var current_node = EditorPlugin.new().get_editor_interface().get_selection().get_selected_nodes()[0]
#	print("Cur = "+str(current_node))
#	print("Cur0 = "+str(current_node[0]))
	print("g")

	current_node.add_child(item)
	print("h")

#	item.set_owner(current_node)
	item.set_owner(get_tree().edited_scene_root)
	print("Created.")
	#item.queue_free()

#func get_edited_root() -> Node:
#	var plugin := EditorPlugin.new()
#	var eds:EditorInterface
#	eds = plugin.get_selection()
#	var selected:EditorInterface
#	selected = eds.get_selected_nodes()[0]
#	if selected:
#		return selected.get_tree().get_edited_scene_root()
#	return null
