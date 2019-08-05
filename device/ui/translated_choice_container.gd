extends Container

func language_changed():
	var lang = TranslationServer.get_locale()

	if not has_node(lang):
		vm.report_errors("translated_choice_container", ["Locale node not found: " + lang])

	for child in get_children():
		if child.name == lang:
			child.visible = true
		else:
			child.visible = false

func _ready():
	add_to_group("ui")

