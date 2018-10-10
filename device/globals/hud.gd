extends Control

var background = null
var force_hide_tooltip = false  # Used by `set_tooltip_visible` to never show

func set_tooltip(text):
	if !$"tooltip":
		return

	if force_hide_tooltip:
		# XXX: This issues an error from Godot that ugc_locked is true,
		# but it appears to be ignorable. At least this works.
		get_tree().call_group_flags(SceneTree.GROUP_CALL_UNIQUE, "game", "reset_overlapped_obj")
		return

	$"tooltip".text = text

	if text:
		printt("hud got tooltip text ", text)
		$"tooltip".show()
	else:
		$"tooltip".hide()

func set_tooltip_visible(p_visible):
	if $"tooltip":
		$"tooltip".visible = p_visible and $"tooltip".text and not force_hide_tooltip

func force_tooltip_visible(p_force_hide_tooltip):
	if $"tooltip":
		# Not visible (false) means it's hidden
		force_hide_tooltip = not p_force_hide_tooltip
		printt("force-hide tooltip:", force_hide_tooltip)
		if force_hide_tooltip:
			$"tooltip".hide()
		else:
			$"tooltip".show()

func inv_toggle():
	$"inventory".toggle()

func _on_inventory_toggle_visibility_changed():
	if $inv_toggle.is_hidden():
		$buttons.hide()
	else:
		$buttons.show()

func _on_hint_pressed():
	printt("hint pressed")
	if background != null:
		background.emit_right_click()

func _on_menu_pressed():
	printt("menu pressed")
	get_tree().call_group("game", "handle_menu_request")

func menu_opened():
	hide()

func menu_closed():
	show()

func set_visible(p_visible):
	visible = p_visible

func _ready():
	add_to_group("hud")
	add_to_group("game")

	if has_node("inv_toggle"):
		$"inv_toggle".connect("pressed", self, "inv_toggle")
		$"inv_toggle".set_focus_mode(Control.FOCUS_NONE)

	if has_node("menu"):
		$"menu".connect("pressed", self, "_on_menu_pressed")
		$"menu".set_focus_mode(Control.FOCUS_NONE)

	# Hide verb menu if hud layer has an action menu
	if has_node("../action_menu"):
		$verb_menu.hide()

