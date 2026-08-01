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

	# Never render a verb-only / stale tooltip with no target.
	if current_target.is_empty():
		text = ""
		return

	var show_verb := true
	if ESCProjectSettingsManager.has_setting(SimpleMouseCycleUISettings.SHOW_VERB_IN_TOOLTIP):
		show_verb = ESCProjectSettingsManager.get_setting(
			SimpleMouseCycleUISettings.SHOW_VERB_IN_TOOLTIP
		)

	text = "[center]"
	text += "[color=#" + color.to_html(false) + "]"
	if show_verb and not current_action.is_empty():
		text += _format_verb(current_action) + " "
	text += current_target

	if waiting_for_target2 and current_target2.is_empty():
		text += " " + current_prep.strip_edges() + " "

	if not current_target2.is_empty():
		text += " " + current_prep.strip_edges() + " " + current_target2

	text += "[/color]"
	text += "[/center]"


func _format_verb(action: String) -> String:
	match action:
		"pickup":
			return "Pick up"
		"look":
			return "Look at"
		"use":
			return "Use"
		"talk":
			return "Talk to"
		"walk":
			return "Walk to"
		_:
			return action.capitalize()
