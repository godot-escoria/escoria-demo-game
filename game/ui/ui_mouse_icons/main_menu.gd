extends Control


func _on_new_game_pressed():
	escoria.new_game()

func _on_load_game_pressed():
	#  Show Loading screen
	pass

func _on_quit_pressed():
	get_tree().quit()
