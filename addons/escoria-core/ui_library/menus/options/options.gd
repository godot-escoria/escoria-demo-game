# An options menu
extends Control


# The back button was pressed
signal back_button_pressed


# The current settings
var backup_settings


# A list of languages already added to the language selection
var _loaded_languages: Array = []


# The settings changed
onready var settings_changed = false


# Initialize the flags
func _ready() -> void:
	var _flags_container: HBoxContainer = \
			$VBoxContainer/MarginContainer/options/flags
	for child in _flags_container.get_children():
		_flags_container.remove_child(child)

	_loaded_languages = []

	for lang in TranslationServer.get_loaded_locales():
		if not lang in _loaded_languages:
			_loaded_languages.append(lang)
			var _lang = TextureRect.new()
			_lang.texture = load(
				"res://addons/escoria-core/ui_library" + \
				"/menus/options/flags/%s.png" % lang
			)
			_flags_container.add_child(_lang)
			_lang.connect("gui_input", self, "_on_language_input", [lang])


# Show the options
func show():
	backup_settings = escoria.settings_manager.get_settings()
	initialize_options(backup_settings)
	visible = true


# Set the sliders to the values of the settings
#
# #### Parameters
# - p_settings: The settings to use
func initialize_options(p_settings):
	var _options = $VBoxContainer/MarginContainer/options
	_options.get_node("general_volume").value = p_settings["master_volume"]
	_options.get_node("sound_volume").value = p_settings["sfx_volume"]
	_options.get_node("music_volume").value = p_settings["music_volume"]
	_options.get_node("speech_volume").value = p_settings["speech_volume"]


# The language was changed
#
# #### Parameters
# - event: The input event from the flag
# - language: The language to set
func _on_language_input(event: InputEvent, language: String):
	if event.is_pressed():
		TranslationServer.set_locale(language)
		escoria.project_settings_manager.set_setting(
			escoria.project_settings_manager.TEXT_LANG,
			language
		)
		settings_changed = true


# Sound volume was changed
#
# #### Parameters
# - value: The new volume level
func _on_sound_volume_changed(value):
	if escoria.project_settings_manager.get_setting(
				escoria.project_settings_manager.SFX_VOLUME
			) != value:
		escoria.project_settings_manager.set_setting(
			escoria.project_settings_manager.SFX_VOLUME,
			value
		)
		escoria.settings_manager.apply_settings()
		settings_changed = true


# Music volume was changed
#
# #### Parameters
# - value: The new volume level
func _on_music_volume_changed(value):
	if escoria.project_settings_manager.get_setting(
				escoria.project_settings_manager.MUSIC_VOLUME
			) != value:
		escoria.project_settings_manager.set_setting(
			escoria.project_settings_manager.MUSIC_VOLUME,
			value
		)
		escoria.settings_manager.apply_settings()
		settings_changed = true


# General volume was changed
#
# #### Parameters
# - value: The new volume level
func _on_general_volume_changed(value):
	if escoria.project_settings_manager.get_setting(
				escoria.project_settings_manager.MASTER_VOLUME
			) != value:
		escoria.project_settings_manager.set_setting(
			escoria.project_settings_manager.MASTER_VOLUME,
			value
		)
		escoria.settings_manager.apply_settings()
		settings_changed = true


# Speech volume was changed
#
# #### Parameters
# - value: The new volume level
func _on_speech_volume_value_changed(value: float) -> void:
	if escoria.project_settings_manager.get_setting(
				escoria.project_settings_manager.SPEECH_VOLUME
			) != value:
		escoria.project_settings_manager.set_setting(
			escoria.project_settings_manager.SPEECH_VOLUME,
			value
		)
		escoria.settings_manager.apply_settings()
		settings_changed = true


# Save the settings
func _on_apply_pressed():
	escoria.settings_manager.custom_settings["a_custom_setting"] = 100
	escoria.settings_manager.save_settings()
	settings_changed = false
	emit_signal("back_button_pressed")


# The back button was pressed
func _on_back_pressed():
	escoria.settings_manager.save_settings_resource_to_project_settings(backup_settings)
	escoria.settings_manager.apply_settings()
	emit_signal("back_button_pressed")
