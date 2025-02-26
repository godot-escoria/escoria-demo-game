@tool
extends Control


const GENERIC_ERROR_NODE   = "Menu/InformationWindows/generic_error_window"


# This variable is set by plugin.gd and used to allow the plugin to interact with the Godot
# editor (open the ESCPlayer scene in the editor once it's created)
var plugin_reference


func _ready() -> void:
	for section_loop in ["RoomCreator", "CharacterCreator", "ItemCreator"]:
		get_node(section_loop).visible = false

	$Menu.visible = true


func NewGame_pressed() -> void:
	pass # Replace with function body.


func NewRoom_pressed() -> void:
	$Menu.visible = false
	$RoomCreator.visible = true
	$RoomCreator.room_creator_reset()


func CharacterCreator_pressed() -> void:
	$Menu.visible = false
	$CharacterCreator.visible = true

	if plugin_reference == null:
		get_node(GENERIC_ERROR_NODE).dialog_text = "Warning!\n\nExporting your character will fail when\n"
		get_node(GENERIC_ERROR_NODE).dialog_text += "running the character creator directly rather than\n"
		get_node(GENERIC_ERROR_NODE).dialog_text += "as a plugin.\n\nPlease open this as a plugin."
		get_node(GENERIC_ERROR_NODE).popup()


func InventoryItem_pressed() -> void:
	$Menu.visible = false
	$ItemCreator.visible = true
