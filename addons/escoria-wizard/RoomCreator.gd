tool
extends Control

const ROOM_NAME                = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/RoomName"
const GLOBAL_ID                = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/GlobalID"
const PLAYER_SCENE             = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/PlayerScene"
const SELECT_PLAYER_SCENE       = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/SelectPlayerScene"
const SELECT_PLAYER_SCENE_SPACER = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/SelectPlayerSceneSpacer"
const USE_EMPTY_PLAYER_BUTTON    = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/UseEmptyPlayerButton"
const ESC_SCRIPT               = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/ESCScript"
const USE_EMPTY_ROOM_SCRIPT      = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/UseEmptyRoomScript"
const USE_EMPTY_ROOM_SPACER      = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/UseEmptyRoomSpacer"
const BACKGROUND_IMAGE         = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/BackgroundImage"
const USE_EMPTY_BACKGROUND      = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/UseEmptyBackground"
const SELECT_BACKGROUND        = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/SelectBackground"
const SELECT_BACKGROUNDSPACER  = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/SelectBackgroundSpacer"
const ROOM_FOLDER_PATH          = "MarginContainer/MarginContainer/VBoxContainer/MarginContainer/GridContainer/RoomFolder"
const ROOM_BACKGROUND          = "MarginContainer/MarginContainer/VBoxContainer/PreviewSection/CenterContainer/RoomBackground"
const BACKGROUND_PREVIEW       = "MarginContainer/MarginContainer/VBoxContainer/PreviewSection/BackgroundPreview"

const SCRIPT_BLANK_TEXT         = "Room will not have a script configured."
const SCRIPT_SELECT_TEXT        = "Please select script."
const PLAYER_BLANK_TEXT         = "Scene will be left blank."
const PLAYER_SELECT_TEXT        = "Please select scene."
const BACKGROUND_BLANK_TEXT     = "Image will be left blank."
const BACKGROUND_SELECT_TEXT    = "Please select image."


var settings_modified: bool


func _ready() -> void:
	room_creator_reset()
	$"InformationWindows/PlayerSceneFileDialog".get_cancel().connect("pressed", self, "PlayerSceneCancelled")
	$"InformationWindows/BackgroundImageFileDialog".get_cancel().connect("pressed", self, "BackgroundFileCancelled")


func PlayerSceneCancelled() -> void:
	if get_node(PLAYER_SCENE).text == PLAYER_SELECT_TEXT:
		get_node(USE_EMPTY_PLAYER_BUTTON).pressed = true


func BackgroundFileCancelled() -> void:
	if get_node(BACKGROUND_IMAGE).text == BACKGROUND_SELECT_TEXT:
		get_node(USE_EMPTY_BACKGROUND).pressed = true


func room_creator_reset() -> void:
	get_node(ROOM_NAME).text = ""
	get_node(GLOBAL_ID).text = ""
	get_node(PLAYER_SCENE).text = PLAYER_BLANK_TEXT
	get_node(SELECT_PLAYER_SCENE).visible = false
	get_node(SELECT_PLAYER_SCENE_SPACER).visible = true
	get_node(USE_EMPTY_PLAYER_BUTTON).pressed = true
	get_node(ESC_SCRIPT).editable = false
	get_node(ESC_SCRIPT).text = SCRIPT_BLANK_TEXT
	get_node(USE_EMPTY_ROOM_SCRIPT).pressed = true
	get_node(BACKGROUND_IMAGE).text = BACKGROUND_BLANK_TEXT
	get_node(USE_EMPTY_ROOM_SPACER).visible = true
	get_node(USE_EMPTY_BACKGROUND).pressed = true
	get_node(SELECT_BACKGROUND).visible = false
	get_node(SELECT_BACKGROUNDSPACER).visible = true
	get_node(BACKGROUND_PREVIEW).visible = true
	get_node(ROOM_BACKGROUND).visible = true
	get_node(BACKGROUND_PREVIEW).texture = null
	get_node(ROOM_FOLDER_PATH).text = ProjectSettings.get_setting("escoria/debug/room_selector_room_dir")
	$InformationWindows/RoomFolderDialog.current_dir = ProjectSettings.get_setting("escoria/debug/room_selector_room_dir")
	settings_modified = false


func _on_RoomName_text_changed(new_text: String) -> void:
	get_node(GLOBAL_ID).text = new_text
	settings_modified = true


func _on_GlobalID_text_changed(new_text: String) -> void:
	settings_modified = true


func _on_UseEmptyPlayerButton_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		get_node(SELECT_PLAYER_SCENE).visible = false
		get_node(SELECT_PLAYER_SCENE_SPACER).visible = true
		get_node(PLAYER_SCENE).text = PLAYER_BLANK_TEXT
	else:
		get_node(SELECT_PLAYER_SCENE).visible = true
		get_node(SELECT_PLAYER_SCENE_SPACER).visible = false
		get_node(PLAYER_SCENE).text = PLAYER_SELECT_TEXT
		$"InformationWindows/PlayerSceneFileDialog".popup_centered()


func _on_SelectPlayerScene_pressed() -> void:
	$"InformationWindows/PlayerSceneFileDialog".visible = true
	$"InformationWindows/PlayerSceneFileDialog".invalidate()


func _on_PlayerSceneFileDialog_file_selected(path: String) -> void:
	settings_modified = true
	get_node(PLAYER_SCENE).text = path


func _on_UseEmptyRoomScript_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		get_node(ESC_SCRIPT).editable = false
		get_node(ESC_SCRIPT).text = SCRIPT_BLANK_TEXT
	else:
		get_node(ESC_SCRIPT).editable = true
		get_node(ESC_SCRIPT).text = "%s.esc" % get_node(GLOBAL_ID).text


func _on_SelectRoomScript_pressed() -> void:
	$"InformationWindows/ESCScriptFileDialog".visible = true
	$"InformationWindows/ESCScriptFileDialog".invalidate()


func _on_ESCScriptFileDialog_file_selected(path: String) -> void:
	settings_modified = true
	get_node(ESC_SCRIPT).text = path


func _on_UseEmptyBackground_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		get_node(SELECT_BACKGROUND).visible = false
		get_node(SELECT_BACKGROUNDSPACER).visible = true
		get_node(BACKGROUND_IMAGE).text = BACKGROUND_BLANK_TEXT
		get_node(BACKGROUND_PREVIEW).texture = null
		get_node(ROOM_BACKGROUND).visible = true
	else:
		get_node(SELECT_BACKGROUND).visible = true
		get_node(SELECT_BACKGROUNDSPACER).visible = false
		get_node(BACKGROUND_IMAGE).text = BACKGROUND_SELECT_TEXT

		var viewport_centre: Vector2 = get_viewport_rect().size / 2
		var dialog_start: Vector2 = $"InformationWindows/BackgroundImageFileDialog".rect_size / 2
		var dialog_pos: Vector2 = viewport_centre - dialog_start
		$"InformationWindows/BackgroundImageFileDialog".rect_position = dialog_pos

		$"InformationWindows/BackgroundImageFileDialog".popup_centered()


func _on_SelectBackground_pressed() -> void:
	var viewport_centre: Vector2 = get_viewport_rect().size / 2
	var dialog_start: Vector2 = $"InformationWindows/BackgroundImageFileDialog".rect_size / 2
	var dialog_pos: Vector2 = viewport_centre - dialog_start
	$"InformationWindows/BackgroundImageFileDialog".rect_position = dialog_pos

	$"InformationWindows/BackgroundImageFileDialog".visible = true
	$"InformationWindows/BackgroundImageFileDialog".invalidate()


func _on_BackgroundImageFileDialog_file_selected(path: String) -> void:
	settings_modified = true

	get_node(BACKGROUND_IMAGE).text = path

	var image_stream_texture:StreamTexture

	image_stream_texture = load(path)

	var preview_size = get_node(ROOM_BACKGROUND).rect_size

	get_node(BACKGROUND_PREVIEW).texture = image_stream_texture
	get_node(ROOM_BACKGROUND).visible = false
	set_preview_scale()


func set_preview_scale() -> void:
	var preview_scale = Vector2.ONE
	# Calculate the scale to make the preview as big as possible in the preview window depending on
	# the height to width ratio of the frame
	var preview_size = get_node(ROOM_BACKGROUND).get_size()
#	get_node(BACKGROUND_PREVIEW).rect_scale = Vector2.ONE
	var image_size = get_node(BACKGROUND_PREVIEW).texture.get_size()

	preview_scale.x =  preview_size.x / image_size.x
	preview_scale.y =  preview_size.y / image_size.y

#	print("scale = "+str(preview_scale)+", preview size = "+str(preview_size)+", image_size = "+str(image_size))
	if preview_scale.y > preview_scale.x:
		get_node(BACKGROUND_PREVIEW).rect_scale = Vector2(preview_scale.x, preview_scale.x)
	else:
		# Image width will hit the preview boundary before the height will
		get_node(BACKGROUND_PREVIEW).rect_scale = Vector2(preview_scale.y, preview_scale.y)


func _on_ClearButton_pressed() -> void:
	if settings_modified:
		$InformationWindows/ClearConfirmationDialog.popup_centered()


func _on_MainMenuButton_pressed() -> void:
	if settings_modified:
		$InformationWindows/MainMenuConfirmationDialog.popup_centered()
	else:
		get_node("../Menu").visible = true
		get_node("../RoomCreator").visible = false


func _on_ClearConfirmationDialog_confirmed() -> void:
	room_creator_reset()


func _on_MainMenuConfirmationDialog_confirmed() -> void:
	get_node("../Menu").visible = true
	get_node("../RoomCreator").visible = false


func _on_ChangeRoomFolderButton_pressed() -> void:
	$"InformationWindows/RoomFolderDialog".popup_centered()


func _on_RoomFolderDialog_dir_selected(dir: String) -> void:
	ProjectSettings.set_setting("escoria/debug/room_selector_room_dir", dir)
	get_node(ROOM_FOLDER_PATH).text = dir


func _on_CreateButton_pressed() -> void:
	var RoomName = get_node(ROOM_NAME).text

	if RoomName.length() < 1:
		$"InformationWindows/GenericErrorDialog".dialog_text = "Error!\n\nRoom name must be specified."
		$"InformationWindows/GenericErrorDialog".popup_centered()
		return

	var ScriptName = get_node(ESC_SCRIPT).text

	if get_node(USE_EMPTY_ROOM_SCRIPT).pressed == false:
		if ScriptName.length() < 5 or ! ScriptName.substr(ScriptName.length() - 4) == ".esc":
			$"InformationWindows/GenericErrorDialog".dialog_text = "Error!\n\n" \
			+ "Room ESC script must be a filename ending in '.esc'"
			$"InformationWindows/GenericErrorDialog".popup_centered()
			return

	if "/" in get_node(ESC_SCRIPT).text:
			$"InformationWindows/GenericErrorDialog".dialog_text = "Error!\n\n" \
			+ "Please remove any '/' characters from the name of the Room ESC script."
			$"InformationWindows/GenericErrorDialog".popup_centered()
			return

	var BaseDir = ProjectSettings.get_setting("escoria/debug/room_selector_room_dir")
	var ImageSize = Vector2(1,1)
	var NewRoom = ESCRoom.new()

	NewRoom.name = RoomName
	NewRoom.global_id = get_node(GLOBAL_ID).text

	if ! get_node(ESC_SCRIPT).text == SCRIPT_SELECT_TEXT and ! get_node(ESC_SCRIPT).text == SCRIPT_BLANK_TEXT:
		NewRoom.esc_script = "%s/%s/scripts/%s" % [BaseDir, RoomName, get_node(ESC_SCRIPT).text]

	if ! get_node(PLAYER_SCENE).text == PLAYER_SELECT_TEXT and ! get_node(PLAYER_SCENE).text == PLAYER_BLANK_TEXT:
		var player_scene = load(get_node(PLAYER_SCENE).text)
		NewRoom.player_scene = player_scene

	var Background = ESCBackground.new()
	Background.name = "Background"

	var BackgroundSize = Vector2.ONE

	if ! get_node(BACKGROUND_IMAGE).text == BACKGROUND_SELECT_TEXT and ! get_node(BACKGROUND_IMAGE).text == BACKGROUND_BLANK_TEXT:
		Background.texture = get_node(BACKGROUND_PREVIEW).texture
		BackgroundSize = Background.texture.get_size()
	else:
		# Set TextureRect to have the same size as the Viewport so that the room
		# works even if no texture is set in the TextureRect
		BackgroundSize = Vector2(ProjectSettings.get_setting("display/window/size/width"), \
							ProjectSettings.get_setting("display/window/size/height"))
		Background.rect_size = BackgroundSize

	NewRoom.add_child(Background)

	var NewTerrain = ESCTerrain.new()
	NewTerrain.name = "WalkableArea"
	var NewNavigationPolygonInstance = NavigationPolygonInstance.new()

	var NewNavigationPolygon = NavigationPolygon.new()
	NewNavigationPolygonInstance.navpoly = NewNavigationPolygon

	NewRoom.add_child(NewTerrain)

	NewTerrain.add_child(NewNavigationPolygonInstance)

	var Objects = Node2D.new()
	Objects.name = "RoomObjects"
	NewRoom.add_child(Objects)

	var StartPos = ESCLocation.new()
	StartPos.name = "StartPos"
	StartPos.is_start_location = true
	StartPos.global_id = "%s_start_pos" % RoomName
	StartPos.position = Vector2(int(BackgroundSize.x / 2), int(BackgroundSize.y / 2))
	NewRoom.add_child(StartPos)

	get_tree().edited_scene_root.add_child(NewRoom)
	NewRoom.set_owner(get_tree().edited_scene_root)
	NewNavigationPolygonInstance.set_owner(NewRoom)
	NewTerrain.set_owner(NewRoom)
	Background.set_owner(NewRoom)
	Objects.set_owner(NewRoom)
	StartPos.set_owner(NewRoom)

	var dir = Directory.new()
	dir.make_dir_recursive("%s/%s/scripts" % [BaseDir, RoomName])
	dir.make_dir_recursive("%s/%s/objects" % [BaseDir, RoomName])
	dir.copy("res://addons/escoria-wizard/room_script_template.esc", "%s/%s/scripts/%s" % \
		[BaseDir, RoomName, get_node(ESC_SCRIPT).text])

	# Export scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(get_tree().edited_scene_root.get_node(NewRoom.name))

	# Flag suggestions from https://godotengine.org/qa/50437/how-to-turn-a-node-into-a-packedscene-via-gdscript
	ResourceSaver.save("%s/%s/%s.tscn" % [BaseDir, RoomName, RoomName], \
		packed_scene, ResourceSaver.FLAG_CHANGE_PATH|ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)

	NewRoom.queue_free()
	get_tree().edited_scene_root.get_node(NewRoom.name).queue_free()
	# Scan the filesystem so that the new folders show up in the file browser.
	# Without this you might not see the objects/scripts folders in the filetree.
	var ep = EditorPlugin.new()
	ep.get_editor_interface().get_resource_filesystem().scan()
	ep.free()

	$InformationWindows/CreateCompleteDialog.popup_centered()
