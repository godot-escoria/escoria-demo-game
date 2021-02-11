extends RichTextLabel

var current_target : String

func set_target(target : String) -> void:
	current_target = target
	update_tooltip_text()

func update_tooltip_text():
	bbcode_text = current_target
