# Main_scene is the entry point for Godot Engine. 
# This scene sets up the main menu scene to load.
extends Node


# Start the main menu
func _ready():
	if escoria.main_menu_instance == null:
		escoria.main_menu_instance = escoria.resource_cache.get_resource(
			ProjectSettings.get_setting("escoria/ui/main_menu_scene")
		).instance()
	escoria.call_deferred("add_child", escoria.main_menu_instance)
	
	
