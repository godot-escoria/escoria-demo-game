extends ESCTooltip

func update_tooltip_text():
	bbcode_text = "[center]"
	bbcode_text += "[color=#" + color.to_html(false) + "]"
	bbcode_text += current_target
	bbcode_text += "[/color]"
	bbcode_text += "[/center]"
#	push_align(RichTextLabel.ALIGN_CENTER)
#	push_color(color)
#	append_bbcode(current_target)
#	pop()
#	pop()
	update_size()
