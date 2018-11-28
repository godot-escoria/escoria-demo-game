extends Control

var background = null

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
	vm.reset_overlapped_obj()
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

