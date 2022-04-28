# Manages settings
class_name ESCSettingsManager


# Template for settings filename
const SETTINGS_TEMPLATE: String = "settings.tres"

# Variable containing the settings folder obtained from Project Settings
var settings_folder: String


var custom_settings: Dictionary


# Constructor of ESCSaveManager object.
func _init():
	# We leave the calls to ProjectSettings as-is since this constructor can be
	# called from escoria.gd's own.
	settings_folder = ProjectSettings.get_setting("escoria/main/settings_path")


# Apply the loaded settings
func apply_settings() -> void:
	if not Engine.is_editor_hint():
		escoria.logger.info("******* settings loaded")
		
		var master_volume: float = escoria.project_settings_manager.get_setting(
			escoria.project_settings_manager.MASTER_VOLUME
		)
		var music_volume: float = escoria.project_settings_manager.get_setting(
			escoria.project_settings_manager.MUSIC_VOLUME
		)
		var speech_volume: float = escoria.project_settings_manager.get_setting(
			escoria.project_settings_manager.SPEECH_VOLUME
		)
		var sfx_volume: float = escoria.project_settings_manager.get_setting(
			escoria.project_settings_manager.SFX_VOLUME
		)
		
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(escoria.BUS_MASTER),
			linear2db(master_volume)
		)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(escoria.BUS_SFX),
			linear2db(sfx_volume)
		)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(escoria.BUS_MUSIC),
			linear2db(music_volume)
		)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(escoria.BUS_SPEECH),
			linear2db(speech_volume)
		)
		TranslationServer.set_locale(
			escoria.project_settings_manager.get_setting(
				escoria.project_settings_manager.TEXT_LANG
			)
		)

		escoria.game_scene.apply_custom_settings(custom_settings)


func save_settings_resource_to_project_settings(settings: ESCSaveSettings):
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.TEXT_LANG,
		settings.text_lang
	)
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.VOICE_LANG,
		settings.voice_lang
	)
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.SPEECH_ENABLED,
		settings.speech_enabled
	)
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.MASTER_VOLUME,
		settings.master_volume
	)
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.MUSIC_VOLUME,
		settings.music_volume
	)
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.SFX_VOLUME,
		settings.sfx_volume
	)
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.SPEECH_VOLUME,
		settings.speech_volume
	)
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.FULLSCREEN,
		settings.fullscreen
	)
	escoria.project_settings_manager.set_setting(
		escoria.project_settings_manager.SKIP_DIALOGS,
		settings.skip_dialogs
	)
	custom_settings = settings.custom_settings


# Load the game settings from the settings file
func load_settings():
	var save_settings_path: String = \
			settings_folder.plus_file(SETTINGS_TEMPLATE)
	var file: File = File.new()
	if not file.file_exists(save_settings_path):
		escoria.logger.report_warnings(
			"esc_save_manager.gd:load_settings()",
			["Settings file %s doesn't exist" % save_settings_path,
			"Setting default settings."])
		save_settings()
	
	var settings: ESCSaveSettings = load(save_settings_path)
	save_settings_resource_to_project_settings(settings)


func get_settings() -> ESCSaveSettings:
	var settings: ESCSaveSettings = ESCSaveSettings.new()
	var plugin_config = ConfigFile.new()
	plugin_config.load("res://addons/escoria-core/plugin.cfg")
	settings.escoria_version = plugin_config.get_value("plugin", "version")
	
	settings.text_lang = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.TEXT_LANG
	)
	settings.voice_lang = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.VOICE_LANG
	)
	settings.speech_enabled = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.SPEECH_ENABLED
	)
	settings.master_volume = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.MASTER_VOLUME
	)
	settings.music_volume = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.MUSIC_VOLUME
	)
	settings.sfx_volume = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.SFX_VOLUME
	)
	settings.speech_volume = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.SPEECH_VOLUME
	)
	settings.fullscreen = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.FULLSCREEN
	)
	settings.skip_dialogs = escoria.project_settings_manager.get_setting(
		escoria.project_settings_manager.SKIP_DIALOGS
	)
	settings.custom_settings = custom_settings
	return settings


# Save the game settings in the settings file.
func save_settings():
	var settings = get_settings()

	var directory: Directory = Directory.new()
	if not directory.dir_exists(settings_folder):
		directory.make_dir_recursive(settings_folder)

	var save_path = settings_folder.plus_file(SETTINGS_TEMPLATE)
	var error: int = ResourceSaver.save(save_path, settings)
	if error != OK:
		escoria.logger.report_errors(
			"esc_save_manager.gd:save_settings()",
			["There was an issue writing settings %s" % save_path])
