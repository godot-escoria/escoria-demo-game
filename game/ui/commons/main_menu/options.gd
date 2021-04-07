extends Control

func _ready():
	var locale = TranslationServer.get_locale()

func greyout_other_languages(except_lang : String) -> void:
	pass

func _on_language_input(event : InputEvent, language : String):
	if event.is_pressed():
		TranslationServer.set_locale(language)
