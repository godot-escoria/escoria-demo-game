extends Control


func _ready():
	escoria.esc_level_runner.set_sound_state(["bg_music", 
		"res://game/sfx/Game-Menu_Looping.mp3", true])

func _on_new_game_pressed():
	escoria.new_game()

func _on_load_game_pressed():
	#  Show Loading screen
	pass

func _on_quit_pressed():
	get_tree().quit()


func _on_continue_pressed():
	pass # Replace with function body.
