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

func _on_menu_mouse_entered():
	# printt("menu mouse entered")
	if vm.tooltip and vm.tooltip.visible:
		vm.tooltip.force_tooltip_visible(false)

func _on_menu_mouse_exited():
	# printt("menu mouse exited")
	if vm.tooltip:
		assert not vm.tooltip.visible

		vm.tooltip.force_tooltip_visible(true)
		vm.tooltip.update()

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
		var conn_err = $"inv_toggle".connect("pressed", self, "inv_toggle")
		if conn_err:
			vm.report_errors("hud", ["inv_toggle.pressed -> inv_toggle error: " + String(conn_err)])

		$"inv_toggle".set_focus_mode(Control.FOCUS_NONE)

	if has_node("menu"):
		var conn_err = $"menu".connect("pressed", self, "_on_menu_pressed")
		if conn_err:
			vm.report_errors("hud", ["menu.pressed -> _on_menu_pressed error: " + String(conn_err)])

		conn_err = $"menu".connect("mouse_entered", self, "_on_menu_mouse_entered")
		if conn_err:
			vm.report_errors("hud", ["menu.mouse_entered -> _on_menu_mouse_entered error: " + String(conn_err)])

		conn_err = $"menu".connect("mouse_exited", self, "_on_menu_mouse_exited")
		if conn_err:
			vm.report_errors("hud", ["menu.mouse_exited -> _on_menu_mouse_exited error: " + String(conn_err)])

		$"menu".set_focus_mode(Control.FOCUS_NONE)

	# Hide verb menu if hud layer has an action menu
	if has_node("../action_menu"):
		$verb_menu.hide()

