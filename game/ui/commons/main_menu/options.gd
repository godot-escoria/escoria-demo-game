extends Control

func _ready():
	initialize_options(escoria.settings)

func initialize_options(p_settings):
	$options/general_volume.value = p_settings["master_volume"]
	$options/sound_volume.value = p_settings["sfx_volume"]
	$options/music_volume.value = p_settings["music_volume"]

func greyout_other_languages(except_lang : String) -> void:
	pass

func _on_language_input(event : InputEvent, language : String):
	if event.is_pressed():
		TranslationServer.set_locale(language)
		escoria.settings["text_lang"] = language
		escoria.esc_runner.save_data.save_settings(escoria.settings, null)


func _on_sound_volume_changed(value):
	escoria.settings["sfx_volume"] = value
	escoria.esc_runner.save_data.save_settings(escoria.settings, null)
	escoria._on_settings_loaded(escoria.settings)

func _on_music_volume_changed(value):
	escoria.settings["music_volume"] = value
	escoria.esc_runner.save_data.save_settings(escoria.settings, null)
	escoria._on_settings_loaded(escoria.settings)


func _on_general_volume_changed(value):
	escoria.settings["master_volume"] = value
	escoria.esc_runner.save_data.save_settings(escoria.settings, null)
	escoria._on_settings_loaded(escoria.settings)
