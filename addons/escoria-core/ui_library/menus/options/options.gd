extends Control

signal back_button_pressed

onready var settings_changed = false
var backup_settings


# A list of languages already added to the language selection
var _loaded_languages: Array = []


func _ready() -> void:
	var _flags_container: HBoxContainer = \
			$CenterContainer/VBoxContainer/MarginContainer/options/flags
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


func show():
	backup_settings = escoria.settings.duplicate()
	initialize_options(escoria.settings)
	visible = true


func initialize_options(p_settings):
	var _options = $CenterContainer/VBoxContainer/MarginContainer/options
	_options.get_node("general_volume").value = p_settings["master_volume"]
	_options.get_node("sound_volume").value = p_settings["sfx_volume"]
	_options.get_node("music_volume").value = p_settings["music_volume"]
	_options.get_node("speech_volume").value = p_settings["speech_volume"]


func _on_language_input(event: InputEvent, language: String):
	if event.is_pressed():
		TranslationServer.set_locale(language)
		escoria.settings["text_lang"] = language
		settings_changed = true


func _on_sound_volume_changed(value):
	escoria.settings["sfx_volume"] = value
	escoria._on_settings_loaded(escoria.settings)
	settings_changed = true


func _on_music_volume_changed(value):
	escoria.settings["music_volume"] = value
	escoria._on_settings_loaded(escoria.settings)
	settings_changed = true
	

func _on_general_volume_changed(value):
	escoria.settings["master_volume"] = value
	escoria._on_settings_loaded(escoria.settings)
	settings_changed = true
	

func _on_apply_pressed():
	escoria.save_manager.save_settings()
	settings_changed = false
	emit_signal("back_button_pressed")


func _on_back_pressed():
	escoria.settings = backup_settings
	escoria._on_settings_loaded(escoria.settings)
	emit_signal("back_button_pressed")


func _on_speech_volume_value_changed(value: float) -> void:
	escoria.settings["speech_volume"] = value
	escoria._on_settings_loaded(escoria.settings)
	settings_changed = true
