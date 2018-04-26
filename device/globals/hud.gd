extends Control

var background = null

func set_tooltip(text):
	if text:
		printt("hud got tooltip text ", text)
	get_node("tooltip").set_text(text)

func inv_toggle():
	#get_node("inventory").toggle()
	pass


func _on_inv_toggle_vis_chaged():
	if (get_node("inv_toggle").is_hidden()):
		get_node("buttons").hide()
	else:
		get_node("buttons").show()

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

func add_inv_reveal():
	var reopen_inv = Control.new()
	var inventory = get_node("inventory")
	
	add_child(reopen_inv)

	reopen_inv.set_position(inventory.get_position())
	reopen_inv.set_size(inventory.get_size())
	reopen_inv.set_rotation_degrees(inventory.get_rotation_degrees())
	reopen_inv.set_scale(inventory.get_scale())

	reopen_inv.connect("mouse_entered",inventory,"open")

func _ready():
	add_to_group("hud")
	add_to_group("game")

	# Hide verb menu if hud layer has an action menu
	if has_node("../action_menu"):
		$verb_menu.hide()

	if has_node("inventory"):
		add_inv_reveal()