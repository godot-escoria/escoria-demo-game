extends Control

export(String, FILE) var bg_sound

var continue_button
var confirm_popup = null
var labels = []

func load_autosave():
	vm.load_autosave()

func can_continue():
	if not main.get_current_scene():
		return false

	return (main.get_current_scene() is esc_type.SCENE) || vm.save_data.autosave_available()

func button_clicked():
	# play a clicking sound here?
	pass

func new_game_pressed():
	button_clicked()
	if main.get_current_scene() is esc_type.SCENE:
		confirm_popup = main.load_menu(ProjectSettings.get_setting("escoria/ui/confirm_popup"))
		confirm_popup.start("UI_NEW_GAME_CONFIRM",self,"start_new_game")
	else:
		start_new_game(true)

func start_new_game(p_confirm):
	if !p_confirm:
		return
	vm.load_file(ProjectSettings.get_setting("escoria/platform/game_start_script"))
	vm.run_game()

func continue_pressed():
	button_clicked()
	if main.get_current_scene() is esc_type.SCENE:
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

func instructions_pressed():
	button_clicked()
	main.load_menu(ProjectSettings.get_setting("escoria/ui/instructions"))

func close():
	main.menu_close(self)
	queue_free()

func input(event):
	if event.is_pressed() && !event.is_echo() && event.is_action("menu_request"):
		if main.get_current_scene() is esc_type.SCENE:
			close()

func menu_collapsed():
	close()

func exit_pressed():
	button_clicked()
	confirm_popup = main.load_menu(ProjectSettings.get_setting("escoria/ui/confirm_popup"))
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
	if not continue_button:
		return

	if vm.continue_enabled and can_continue():
		continue_button.set_disabled(false)
	else:
		continue_button.set_disabled(true)

func set_bg_sound():
	var stream = $"stream"

	var resource = load(bg_sound)
	stream.stream = resource
	assert stream.stream
	resource.set_loop(true)
	stream.volume_db = 1  # TODO: Should have all this in ProjectSettings
	stream.play()

func _find_lang_buttons(node=self):
	for c in node.get_children():
		if c is preload("res://ui/lang_button.gd"):
			c.connect("language_selected", self, "_on_language_selected")
		else:
			_find_lang_buttons(c)

func _on_language_selected(lang):
	vm.settings.text_lang=lang
	TranslationServer.set_locale(vm.settings.text_lang)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "ui", "language_changed")
	vm.save_settings()

func _find_menu_buttons(node=self):
	for c in node.get_children():
		if c is preload("res://ui/menu_button.gd") or c is preload("res://ui/menu_texturebutton.gd"):
			var sighandler_name = c.name + "_pressed"

			c.connect("pressed", self, sighandler_name)

			if c.name == "continue":
				continue_button = c
		else:
			_find_menu_buttons(c)

func _ready():
	set_process_input(true)

	if has_node("stream") and bg_sound:
		set_bg_sound()

	# Make sure menu buttons have the correct language when the menu is opened
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "ui", "language_changed")

	main.menu_open(self)

	_find_labels()

	_find_menu_buttons()

	_find_lang_buttons()

	add_to_group("ui")

	call_deferred("set_continue_button")

	if !ProjectSettings.get_setting("escoria/platform/exit_button"):
		get_node("exit").hide()

