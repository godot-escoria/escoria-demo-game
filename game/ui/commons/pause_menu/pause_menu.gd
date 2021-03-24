extends Control


func _on_continue_pressed():
	escoria.main.current_scene.game.pause_game()


func _on_save_game_pressed():
	pass


func _on_load_game_pressed():
	pass


func _on_quit_pressed():
	get_tree().quit()
