# An options menu
extends Control


# The back button was pressed
signal back_button_pressed


# Custom setting key
const CUSTOM_SETTING: String = "a_custom_setting"


# The current settings
var backup_settings


# A list of languages already added to the language selection
var _loaded_languages: Array = []


# The settings changed
@onready var changed = false


# Initialize the flags
func _ready() -> void:
	var flags_container: HBoxContainer = \
			$VBoxContainer/MarginContainer/options/flags
	for child in flags_container.get_children():
		flags_container.remove_child(child)
		child.queue_free()

	_loaded_languages = []

	for language in TranslationServer.get_loaded_locales():
		if not language in _loaded_languages:
			_loaded_languages.append(language)
			var language_item = TextureRect.new()
			language_item.texture = load(
				"res://addons/escoria-core/ui_library" + \
				"/menus/options/flags/%s.png" % language
			)
			flags_container.add_child(language_item)
			language_item.connect("gui_input", Callable(self, "_on_language_input").bind(language))


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
	var options = $VBoxContainer/MarginContainer/options
	options.get_node("general_volume").value = p_settings["master_volume"]
	options.get_node("sound_volume").value = p_settings["sfx_volume"]
	options.get_node("music_volume").value = p_settings["music_volume"]
	options.get_node("speech_volume").value = p_settings["speech_volume"]
	options.get_node("ambient_volume").value = p_settings["ambient_volume"]
	options.get_node("fullscreen").set_pressed_no_signal(p_settings["fullscreen"])


# The language was changed
#
# #### Parameters
# - event: The input event from the flag
# - language: The language to set
func _on_language_input(event: InputEvent, language: String):
	if event.is_pressed():
		TranslationServer.set_locale(language)
		ESCProjectSettingsManager.set_setting(
			ESCProjectSettingsManager.TEXT_LANG,
			language
		)
		changed = true


# Sound volume was changed
#
# #### Parameters
# - value: The new volume level
func _on_sound_volume_changed(value):
	if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.SFX_VOLUME
			) != value:
		ESCProjectSettingsManager.set_setting(
			ESCProjectSettingsManager.SFX_VOLUME,
			value
		)
		escoria.settings_manager.apply_settings()
		changed = true


# Music volume was changed
#
# #### Parameters
# - value: The new volume level
func _on_music_volume_changed(value):
	if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.MUSIC_VOLUME
			) != value:
		ESCProjectSettingsManager.set_setting(
			ESCProjectSettingsManager.MUSIC_VOLUME,
			value
		)
		escoria.settings_manager.apply_settings()
		changed = true


# General volume was changed
#
# #### Parameters
# - value: The new volume level
func _on_general_volume_changed(value):
	if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.MASTER_VOLUME
			) != value:
		ESCProjectSettingsManager.set_setting(
			ESCProjectSettingsManager.MASTER_VOLUME,
			value
		)
		escoria.settings_manager.apply_settings()
		changed = true


# Speech volume was changed
#
# #### Parameters
# - value: The new volume level
func _on_speech_volume_value_changed(value: float) -> void:
	if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.SPEECH_VOLUME
			) != value:
		ESCProjectSettingsManager.set_setting(
			ESCProjectSettingsManager.SPEECH_VOLUME,
			value
		)
		escoria.settings_manager.apply_settings()
		changed = true

# Ambient volume was changed
#
# #### Parameters
# - value: The new volume level
func _on_ambient_volume_value_changed(value: float) -> void:
	if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.AMBIENT_VOLUME
			) != value:
		ESCProjectSettingsManager.set_setting(
			ESCProjectSettingsManager.AMBIENT_VOLUME,
			value
		)
		escoria.settings_manager.apply_settings()
		changed = true


# Fullscreen was changed
#
# #### Parameters
# - button_pressed: Fullscreen (true) or windowed (false)
func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.FULLSCREEN
			) != button_pressed:
		ESCProjectSettingsManager.set_setting(
			ESCProjectSettingsManager.FULLSCREEN,
			button_pressed
		)
		escoria.settings_manager.apply_settings()
		changed = true


# Save the settings
func _on_apply_pressed():
	escoria.settings_manager.custom_settings[CUSTOM_SETTING] = 100
	escoria.settings_manager.save_settings()
	changed = false
	back_button_pressed.emit()


# The back button was pressed
func _on_back_pressed():
	escoria.settings_manager.save_settings_resource_to_project_settings(backup_settings)
	escoria.settings_manager.apply_settings()
	back_button_pressed.emit()
