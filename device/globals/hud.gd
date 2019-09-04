extends Control

var background = null

var inv_toggle_rect = null
var menu_toggle_rect = null

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

func hud_button_entered():
	# printt("hud button mouse entered")
	vm.hover_teardown()

func hud_button_exited():
	# printt("hud button mouse exited")
	vm.hover_rebuild()

func menu_opened():
	hide()

func menu_closed():
	show()

func set_visible(p_visible):
	visible = p_visible

func setup_inv_toggle():
	var conn_err = $"inv_toggle".connect("pressed", self, "inv_toggle")
	if conn_err:
		vm.report_errors("hud", ["inv_toggle.pressed -> inv_toggle error: " + String(conn_err)])

	conn_err = $"inv_toggle".connect("mouse_entered", self, "hud_button_entered")
	if conn_err:
		vm.report_errors("hud", ["inv_toggle.mouse_entered -> hud_button_entered error: " + String(conn_err)])

	conn_err = $"inv_toggle".connect("mouse_exited", self, "hud_button_exited")
	if conn_err:
		vm.report_errors("hud", ["inv_toggle.mouse_exited -> hud_button_exited error: " + String(conn_err)])

	$"inv_toggle".set_focus_mode(Control.FOCUS_NONE)

	inv_toggle_rect = Rect2($"inv_toggle".rect_global_position, $"inv_toggle".rect_size)

func setup_menu_toggle():
	var conn_err = $"menu".connect("pressed", self, "_on_menu_pressed")
	if conn_err:
		vm.report_errors("hud", ["menu.pressed -> _on_menu_pressed error: " + String(conn_err)])

	conn_err = $"menu".connect("mouse_entered", self, "hud_button_entered")
	if conn_err:
		vm.report_errors("hud", ["menu.mouse_entered -> hud_button_entered error: " + String(conn_err)])

	conn_err = $"menu".connect("mouse_exited", self, "hud_button_exited")
	if conn_err:
		vm.report_errors("hud", ["menu.mouse_exited -> hud_button_exited error: " + String(conn_err)])

	$"menu".set_focus_mode(Control.FOCUS_NONE)

	menu_toggle_rect = Rect2($"menu".rect_global_position, $"menu".rect_size)

func _ready():
	add_to_group("hud")
	add_to_group("game")

	if has_node("inv_toggle"):
		setup_inv_toggle()

	if has_node("menu"):
		setup_menu_toggle()

	# Hide verb menu if hud layer has an action menu
	if has_node("../action_menu"):
		$verb_menu.hide()

