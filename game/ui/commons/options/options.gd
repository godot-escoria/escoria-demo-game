extends Control

signal back_button_pressed

onready var settings_changed = false
var backup_settings


func show():
	backup_settings = escoria.settings.duplicate()
	initialize_options(escoria.settings)
	visible = true


func initialize_options(p_settings):
	$options/general_volume.value = p_settings["master_volume"]
	$options/sound_volume.value = p_settings["sfx_volume"]
	$options/music_volume.value = p_settings["music_volume"]


func greyout_other_languages(_except_lang: String) -> void:
	pass


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
