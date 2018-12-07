extends Label

export(String) var translation_id

func language_changed():
	if translation_id:
		var ptext = TranslationServer.translate(translation_id)
		self.text = ptext

func _ready():
	add_to_group("ui")

