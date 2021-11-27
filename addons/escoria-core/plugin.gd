# Plugin script to initialize Escoria
tool
extends EditorPlugin


# Setup Escoria
func _enter_tree():
	add_autoload_singleton(
		"escoria", 
		"res://addons/escoria-core/game/escoria.tscn"
	)
	
	# Add input actions in InputMap
	InputMap.add_action("switch_action_verb")
	InputMap.add_action("esc_show_debug_prompt")
	
	# Define standard settings
	ProjectSettings.set_setting(
		"application/run/main_scene", 
		"res://addons/escoria-core/game/main_scene.tscn"
	)
	
	ProjectSettings.set_setting(
		"audio/default_bus_layout", 
		"res://addons/escoria-core/default_bus_layout.tres"
	)
	

func _ready():
	# Prepare settings
	set_escoria_main_settings()
	set_escoria_debug_settings()
	set_escoria_ui_settings()
	set_escoria_sound_settings()
	set_escoria_platform_settings()


# Prepare the settings in the Escoria UI category
func set_escoria_ui_settings():
	escoria.register_setting(
		"escoria/ui/default_dialog_type",
		"",
		{
			"type": TYPE_STRING
		}
	)
	
	escoria.register_setting(
		"escoria/ui/game_scene",
		"",
		{
			"name": "escoria/ui/game_scene",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tscn, *.scn"
		}
	)
	
	escoria.register_setting(
		"escoria/ui/items_autoregister_path",
		"res://game/items/escitems/",
		{
			"name": "escoria/ui/items_autoregister_path",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)
	
	escoria.register_setting(
		"escoria/ui/default_transition",
		"curtain",
		{
			"name": "escoria/ui/default_transition",
			"type": TYPE_STRING
		}
	)
	
	escoria.register_setting(
		"escoria/ui/transition_paths",
		[
			"res://addons/escoria-core/game/scenes/transitions/shaders/"
		],
		{
			"name": "escoria/ui/transition_paths",
			"type": TYPE_STRING_ARRAY,
			"hint": PROPERTY_HINT_DIR
		}
	)
	
	escoria.register_setting(
		"escoria/ui/inventory_item_size",
		Vector2(72, 72),
		{
			"name": "escoria/ui/inventory_item_size",
			"type": TYPE_VECTOR2
		}
	)
	
	escoria.register_setting(
		"escoria/ui/dialog_managers",
		[],
		{
			"type": TYPE_STRING_ARRAY
		}
	)

# Prepare the settings in the Escoria main category
func set_escoria_main_settings():
	escoria.register_setting(
		"escoria/main/game_version", 
		"",
		{
			"type": TYPE_STRING
		}
	)
	
	escoria.register_setting(
		"escoria/main/game_start_script", 
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.esc"
		}
	)
	
	escoria.register_setting(
		"escoria/main/force_quit",
		true,
		{
			"type": TYPE_BOOL
		}
	)
	
	escoria.register_setting(
		"escoria/main/command_directories", 
		[
			"res://addons/escoria-core/game/core-scripts/esc/commands"
		],
		{
			"type": TYPE_ARRAY,
		}
	)
	
	escoria.register_setting(
		"escoria/main/text_lang", 
		TranslationServer.get_locale(),
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE
		}
	)
	
	escoria.register_setting(
		"escoria/main/voice_lang", 
		TranslationServer.get_locale(),
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE
		}
	)
	
	escoria.register_setting(
		"escoria/main/savegames_path", 
		"user://saves/",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)
	
	escoria.register_setting(
		"escoria/main/settings_path", 
		"user://",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)


# Prepare the settings in the Escoria debug category
func set_escoria_debug_settings():
	escoria.register_setting(
		"escoria/debug/terminate_on_warnings",
		false,
		{
			"type": TYPE_BOOL
		}
	)
	
	escoria.register_setting(
		"escoria/debug/terminate_on_errors",
		true,
		{
			"type": TYPE_BOOL
		}
	)
	
	escoria.register_setting(
		"escoria/debug/development_lang",
		"en",
		{
			"type": TYPE_STRING
		}
	)
	
	escoria.register_setting(
		"escoria/debug/log_level", 
		"ERROR",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "ERROR,WARNING,INFO,DEBUG"
		}
	)
	
	escoria.register_setting(
		"escoria/debug/log_file_path", 
		"user://",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)
	
	escoria.register_setting(
		"escoria/debug/crash_message", 
		"We're sorry, but the game crashed. Please send us the " +
		"following files:\n\n%s",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT
		}
	)
	
	escoria.register_setting(
		"escoria/debug/enable_room_selector", 
		false,
		{
			"type": TYPE_BOOL
		}
	)
	
	escoria.register_setting(
		"escoria/debug/room_selector_room_dir",
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)


# Prepare the settings in the Escoria sound settings
func set_escoria_sound_settings():
	escoria.register_setting(
		"escoria/sound/master_volume", 
		1,
		{
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)
	
	escoria.register_setting(
		"escoria/sound/music_volume", 
		1,
		{
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)
	
	escoria.register_setting(
		"escoria/sound/sfx_volume", 
		1,
		{
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)
	
	escoria.register_setting(
		"escoria/sound/speech_volume",
		1,
		{
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1"
		}
	)
	
	escoria.register_setting(
		"escoria/sound/speech_enabled",
		1,
		{
			"type": TYPE_BOOL
		}
	)

	escoria.register_setting(
		"escoria/sound/speech_folder",
		"res://speech",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)
	
	escoria.register_setting(
		"escoria/sound/speech_extension", 
		"ogg", 
		{
			"type": TYPE_STRING
		}
	)


# Prepare the settings in the Escoria platform category and may need special
# setting per build
func set_escoria_platform_settings():
	# Skip cache - certain platforms (esp. mobile) lack memory for caching
	# scenes.
	# If set to true, all generic scenes (UI, inventory, etc) will be loaded
	# as any other scene.
	escoria.register_setting(
		"escoria/platform/skip_cache",
		false,
		{
			"type": TYPE_BOOL
		}
	)
	
	escoria.register_setting(
		"escoria/platform/skip_cache.mobile",
		true,
		{
			"type": "TYPE_BOOL"
		}
	)


# Uninstall plugin
func _exit_tree():
	remove_autoload_singleton("escoria")
	
	InputMap.erase_action("switch_action_verb")
	InputMap.erase_action("esc_show_debug_prompt")
