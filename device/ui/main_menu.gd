extends Control

var confirm_popup = null
var labels = []

func load_autosave():
	vm.load_autosave()

func can_continue():
	return (main.get_current_scene() is preload("res://globals/scene.gd")) || vm.save_data.autosave_available()

func button_clicked():
	# play a clicking sound here?
	pass

func newgame_pressed():
	button_clicked()
	if main.get_current_scene() is preload("res://globals/scene.gd"):
		confirm_popup = main.load_menu("res://ui/confirm_popup.tscn")
		confirm_popup.start("UI_NEW_GAME_CONFIRM",self,"start_new_game")
	else:
		start_new_game(true)

func start_new_game(p_confirm):
	if !p_confirm:
		return
	vm.load_file("res://game/game.esc")

func continue_pressed():
	button_clicked()
	if main.get_current_scene() is preload("res://globals/scene.gd"):
		main.menu_collapse()
	else:
		if vm.continue_enabled:
			load_autosave()

func save_pressed():
	button_clicked()
	main.load_menu(ProjectSettings.get_setting("escoria/ui/savegames"))

func settings_pressed():
	button_clicked()
	main.load_menu(ProjectSettings.get_setting("escoria/ui/settings"))

func credits_pressed():
	button_clicked()
	main.load_menu(ProjectSettings.get_setting("escoria/ui/credits"))

func close():
	main.menu_close(self)
	queue_free()

func input(event):
	if event.is_pressed() && !event.is_echo() && event.is_action("menu_request"):
		if main.get_current_scene() is preload("res://globals/scene.gd"):
			close()

func menu_collapsed():
	close()

func _on_exit_pressed():
	button_clicked()
	confirm_popup = main.load_menu("res://ui/confirm_popup.tscn")
	confirm_popup.start("UI_QUIT_CONFIRM",self,"_quit_game")

func _quit_game(p_confirm):
	if !p_confirm:
		return
	get_tree().quit()

func language_changed():
	for l in labels:
		l.set_text(l.get_name())

func _find_labels(p = null):
	if p == null:
		p = self
	if p is Label:
		labels.push_back(p)
	for i in range(0, p.get_child_count()):
		_find_labels(p.get_child(i))

func set_continue_button():
	if vm.continue_enabled && can_continue():
		get_node("continue").set_disabled(false)
		#get_node("continue").show()
	else:
		get_node("continue").set_disabled(true)
		#get_node("continue").hide()


func _on_language_selected(lang):
	vm.settings.text_lang=lang
	TranslationServer.set_locale(vm.settings.text_lang)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "ui", "language_changed")
	vm.save_settings()

func _ready():
	get_node("new_game").connect("pressed", self, "newgame_pressed")
	get_node("continue").connect("pressed", self, "continue_pressed")
	#get_node("save").connect("pressed", self, "save_pressed")
	get_node("exit").connect("pressed", self, "_on_exit_pressed")
	#get_node("settings").connect("pressed", self, "settings_pressed")
	#get_node("credits").connect("pressed",self,"credits_pressed")
	vm = get_tree().get_root().get_node("vm")
	set_process_input(true)
	#main.set_current_scene(self)

	main.menu_open(self)

	_find_labels()

	add_to_group("ui")

	call_deferred("set_continue_button")

	if !ProjectSettings.get_setting("escoria/platform/exit_button"):
		get_node("exit").hide()


