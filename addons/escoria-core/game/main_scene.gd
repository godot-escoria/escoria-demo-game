# Main_scene is the entry point for Godot Engine. 
# This scene sets up the main menu scene to load.
extends Node


# Start the main menu
func _ready():
	if escoria.main_menu_instance == null:
		if ProjectSettings.get_setting("escoria/ui/main_menu_scene") == "":
			escoria.logger.report_errors("escoria.gd", 
				["Parameter escoria/ui/main_menu_scene is not set!"]
			)
		else:
			escoria.main_menu_instance = escoria.resource_cache.get_resource(
				ProjectSettings.get_setting("escoria/ui/main_menu_scene")
			).instance()
	escoria.call_deferred("add_child", escoria.main_menu_instance)
	
	
