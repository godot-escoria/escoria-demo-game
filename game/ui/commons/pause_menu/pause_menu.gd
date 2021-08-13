extends Control


func _ready():
	self.pause_mode = Node.PAUSE_MODE_PROCESS
	hide()


func _on_continue_pressed():
	escoria.main.current_scene.game.pause_game()


func _on_save_game_pressed():
	$Panel/VBoxContainer.hide()
	$save_game.show()


func _on_load_game_pressed():
	$Panel/VBoxContainer.hide()
	$load_game.refresh_savegames()
	$load_game.show()


func _on_quit_pressed():
	get_tree().quit()


func _on_save_game_back_button_pressed():
	$Panel/VBoxContainer.show()
	$save_game.hide()


func _on_load_game_back_button_pressed():
	$Panel/VBoxContainer.show()
	$load_game.hide()
