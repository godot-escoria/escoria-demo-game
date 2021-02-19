extends ESCTooltip

func update_tooltip_text():
	push_align(RichTextLabel.ALIGN_CENTER)

	if !current_action.empty():
		add_text(current_action + "\t")

	add_text(current_target)

	if waiting_for_target2 and current_target2.empty():
		add_text("\t" + current_prep)

	if !current_target2.empty():
		add_text("\t" + current_prep + "\t" + current_target2)

	pop()
