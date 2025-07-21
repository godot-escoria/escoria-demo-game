extends ESCTooltip


signal tooltip_size_updated


func update_tooltip_text():
	# Need to update size of bbcode rect before updating the text itself otherwise on the
	# first frame the text is wider than the default of 0 and ends up being really tall
	# and setting the wrong vertical margin for the tooltip
	update_size()

	# We signal this here since the processing in this class happens AFTER input
	# processing. We signal here to avoid "lagging" behind a frame since
	# tooltips are presently dependent on the size of the bounding box around
	# the rendered string.
	tooltip_size_updated.emit()

	text = "[center]"
	text += "[color=#" + color.to_html(false) + "]"
	text += current_target
	text += "[/color]"
	text += "[/center]"
#	push_align(RichTextLabel.ALIGN_CENTER)
#	push_color(color)
#	append_bbcode(current_target)
#	pop()
#	pop()
