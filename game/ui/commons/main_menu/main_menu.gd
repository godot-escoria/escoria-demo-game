extends Control


func _ready():
	escoria.esc_level_runner.set_sound_state(["bg_music", 
		"res://game/sfx/Game-Menu_Looping.mp3", true])


func _on_continue_pressed():
	pass





func switch_language(lang : String):
	TranslationServer.set_locale(lang)


func _on_new_game_pressed():
	escoria.new_game()

func _on_load_game_pressed():
	#  Show Loading screen
	pass

func _on_options_pressed():
	$Panel/main.hide()
	$Panel/options.show()

func _on_quit_pressed():
	get_tree().quit()

###########################################################################
###########################################################################
# OPTIONS


func _on_back_pressed():
	$Panel/options.hide()
	$Panel/main.show()
	
