extends Control


func _ready():
	var event = ESCEvent.new(":music")
	event.statements.append(
		ESCCommand.new(
			"set_sound_state _music res://game/sfx/Game-Menu_Looping.mp3 true"
		)
	)
	escoria.event_manager.queue_event(event)
	var rc = yield(event, "finished")
	
	if rc != ESCExecution.RC_OK:
		escoria.logger.report_errors(
			"main_menu: Can't start menu music",
			[
				"set_sound_state returned %d" % rc
			]
		)
		return false
	

func _on_continue_pressed():
	pass


func switch_language(lang: String):
	TranslationServer.set_locale(lang)


func _on_new_game_pressed():
	escoria.new_game()


func _on_load_game_pressed():
	$Panel/CenterContainer/main.hide()
	$Panel/load_game.refresh_savegames()
	$Panel/load_game.show()


func _on_options_pressed():
	$Panel/CenterContainer/main.hide()
	$Panel/options.show()


func _on_quit_pressed():
	get_tree().quit()

###########################################################################
###########################################################################
# OPTIONS

func _on_options_back_button_pressed():
	$Panel/options.hide()
	$Panel/CenterContainer/main.show()


func _on_load_game_back_button_pressed():
	$Panel/load_game.hide()
	$Panel/CenterContainer/main.show()
	
