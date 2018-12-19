extends RichTextLabel

export(String) var translation_id

func language_changed():
	if translation_id:
		var ptext = TranslationServer.translate(translation_id)
		if self.bbcode_enabled:
			self.bbcode_text = ptext
		else:
			self.text = ptext

func _ready():
	add_to_group("ui")

