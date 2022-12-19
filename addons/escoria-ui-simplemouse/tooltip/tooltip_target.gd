extends ESCTooltip

func update_tooltip_text():
	# Need to update size of bbcode rect before updating the text itself otherwise on the
	# first frame the text is wider than the default of 0 and ends up being really tall
	# and setting the wrong vertical margin for the tooltip
	update_size()

	# We make this call here since this processing happens AFTER input processing.
	# We do this to avoid "lagging" behind a frame since tooltips are presently
	# dependent on the size of the bounding box around the rendered string.
	escoria.game_scene.update_tooltip_following_mouse_position()

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
