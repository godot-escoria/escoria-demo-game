# Main_scene is the entry point for Godot Engine. 
# This scene sets up the main menu scene to load.
extends Node


# Start the main menu
func _ready():
	var main_menu_path = ProjectSettings.get_setting(
		"escoria/ui/main_menu_scene"
	)
	var main_menu_scene = load(main_menu_path).instance()
	escoria.call_deferred("add_child", main_menu_scene)
	escoria.main_menu_instance = main_menu_scene
	
