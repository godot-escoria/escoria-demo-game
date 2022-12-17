extends ESCTooltip

func update_tooltip_text():
	# Need to update size of bbcode rect before updating the text itself otherwise on the
	# first frame the text is wider than the default of 0 and ends up being really tall
	# and setting the wrong vertical margin for the tooltip
	update_size()	
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
