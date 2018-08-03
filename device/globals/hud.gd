extends Control

var background = null

func set_tooltip(text):
	if !$"tooltip":
		return

	$"tooltip".text = text

	if text:
		printt("hud got tooltip text ", text)
		$"tooltip".show()
	else:
		$"tooltip".hide()

func set_tooltip_visible(p_visible):
	if $"tooltip":
		$"tooltip".visible = p_visible and $"tooltip".text

func inv_toggle():
	#get_node("inventory").toggle()
	pass


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
	if vm.can_save() && vm.can_interact() && vm.menu_enabled():
		main.load_menu("res://demo/ui/main_menu.xml")
	else:
		#get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "ui_blocked")
		if vm.menu_enabled():
			main.load_menu(ProjectSettings.get_setting("escoria/ui/in_game_menu"))
		else:
			get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "ui_blocked")


func menu_opened():
	hide()

func menu_closed():
	show()

func set_visible(p_visible):
	visible = p_visible

func _ready():
	add_to_group("hud")
	add_to_group("game")

	# Hide verb menu if hud layer has an action menu
	if has_node("../action_menu"):
		$verb_menu.hide()

