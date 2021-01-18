tool
extends EditorPlugin

const autoloads = {
	"escoria": "res://addons/escoria-core/game/escoria.tscn",
	"esctypes": "res://addons/escoria-core/game/core-scripts/escoria_types.gd"
}

func _enter_tree():
	add_autoloads()
	
	add_custom_type("ESCBackground", "Sprite", 
			load("res://addons/escoria-core/game/core-scripts/escbackground.gd"), null)
	add_custom_type("ESCCharacter", "KinematicBody2D", 
			load("res://addons/escoria-core/game/core-scripts/esccharacter.gd"), null)
	add_custom_type("ESCItem", "Area2D", 
			load("res://addons/escoria-core/game/core-scripts/escitem.gd"), null)
	add_custom_type("ESCItemsInventory", "GridContainer", 
			load("res://addons/escoria-core/game/core-scripts/items_inventory.gd"), null)
	add_custom_type("ESCInventoryItem", "TextureButton", 
			load("res://addons/escoria-core/game/core-scripts/inventory_item.gd"), null)
	add_custom_type("ESCPlayer", "KinematicBody2D", 
			load("res://addons/escoria-core/game/core-scripts/escplayer.gd"), null)
	add_custom_type("ESCRoom", "Node2D", 
			load("res://addons/escoria-core/game/core-scripts/escroom.gd"), null)
	add_custom_type("ESCTerrain", "Navigation2D", 
			load("res://addons/escoria-core/game/core-scripts/escterrain.gd"), null)
	
	set_escoria_main_settings()
	set_escoria_debug_settings()
	set_escoria_ui_settings()
	set_escoria_internal_settings()
	
	
func set_escoria_ui_settings():
	if !ProjectSettings.has_setting("escoria/ui/tooltip_follows_mouse"):
		ProjectSettings.set_setting("escoria/ui/tooltip_follows_mouse", true)
	
	if !ProjectSettings.has_setting("escoria/ui/dialogs_folder"):
		ProjectSettings.set_setting("escoria/ui/dialogs_folder", "")
		var dialogs_folder_property_info = {
			"name": "escoria/ui/dialogs_folder",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
		ProjectSettings.add_property_info(dialogs_folder_property_info)
		
	if !ProjectSettings.has_setting("escoria/ui/default_dialog_scene"):
		ProjectSettings.set_setting("escoria/ui/default_dialog_scene", "")
		var default_dialog_scene_property_info = {
			"name": "escoria/ui/default_dialog_scene",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tscn, *.scn"
		}
		ProjectSettings.add_property_info(default_dialog_scene_property_info)
	
	if !ProjectSettings.has_setting("escoria/ui/main_menu_scene"):
		ProjectSettings.set_setting("escoria/ui/main_menu_scene", "")
		var main_menu_scene_property_info = {
			"name": "escoria/ui/main_menu_scene",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tscn, *.scn"
		}
		ProjectSettings.add_property_info(main_menu_scene_property_info)
	
	if !ProjectSettings.has_setting("escoria/ui/game_scene"):
		ProjectSettings.set_setting("escoria/ui/game_scene", "")
		var game_scene_property_info = {
			"name": "escoria/ui/game_scene",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tscn, *.scn"
		}
		ProjectSettings.add_property_info(game_scene_property_info)
	

func set_escoria_main_settings():
	if !ProjectSettings.has_setting("escoria/main/game_start_script"):
		ProjectSettings.set_setting("escoria/main/game_start_script", "")
		var game_start_script_property_info = {
			"name": "escoria/main/game_start_script",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.esc"
		}
		ProjectSettings.add_property_info(game_start_script_property_info)
	
	if !ProjectSettings.has_setting("escoria/main/force_quit"):
		ProjectSettings.set_setting("escoria/main/force_quit", true)
		var force_quit_property_info = {
			"name": "escoria/main/force_quit",
			"type": TYPE_BOOL
		}
		ProjectSettings.add_property_info(force_quit_property_info)
	
	ProjectSettings.set_setting("application/run/main_scene", "res://addons/escoria-core/game/main_scene.tscn")


	
func set_escoria_debug_settings():
	if !ProjectSettings.has_setting("escoria/debug/terminate_on_warnings"):
		ProjectSettings.set_setting("escoria/debug/terminate_on_warnings", false)
	
	if !ProjectSettings.has_setting("escoria/debug/terminate_on_errors"):
		ProjectSettings.set_setting("escoria/debug/terminate_on_errors", true)
	
	# Main language the game is developed in. Useful for translation management
	if !ProjectSettings.has_setting("escoria/debug/development_lang"):
		ProjectSettings.set_setting("escoria/debug/development_lang", "en")
		

func set_escoria_internal_settings():
	if !ProjectSettings.has_setting("escoria/internals/save_data"):
		ProjectSettings.set_setting("escoria/internals/save_data", "")
		var save_data_property_info = {
			"name": "escoria/internals/save_data",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tscn, *.scn"
		}
		ProjectSettings.add_property_info(save_data_property_info)

# Defines platform-specific parameters. Those are the ones that must be re-set for each platform export.
func set_escoria_platform_settings():
	# Skip cache - certain platforms (esp. mobile) lack memory for caching scenes
	# If true, all generic scenes (UI, inventory, etc) will be loaded as any other scene.
	if !ProjectSettings.has_setting("escoria/platform/skip_cache"):
		ProjectSettings.set_setting("escoria/platform/skip_cache", false)
	
	

func add_autoloads():
	for key in autoloads.keys():
		add_autoload_singleton(key, autoloads[key])

func remove_autoloads():
	for key in autoloads.keys():
		if ProjectSettings.has_setting(key):
			remove_autoload_singleton(key)
	

func _exit_tree():
	remove_custom_type("ESCBackground")
	remove_custom_type("ESCCharacter")
	remove_custom_type("ESCItem")
	remove_custom_type("ESCInventoryItem")
	remove_custom_type("ESCItemsInventory")
	remove_custom_type("ESCPlayer")
	remove_custom_type("ESCRoom")
	remove_custom_type("ESCTerrain")
	
	remove_autoloads()
	
	
