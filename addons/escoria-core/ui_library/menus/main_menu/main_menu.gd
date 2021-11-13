# A simple main menu
extends Control


# Start the game
func _on_new_game_pressed():
	escoria.new_game()


# Show the load slots
func _on_load_game_pressed():
	$main.hide()
	$load_game.refresh_savegames()
	$load_game.show()


# Show the options panel
func _on_options_pressed():
	$main.hide()
	$options.show()


# Quit the game
func _on_quit_pressed():
	escoria.quit()


# Hide the options panel again
func _on_options_back_button_pressed():
	$options.hide()
	$main.show()


# Hide the load panel
func _on_load_game_back_button_pressed():
	$load_game.hide()
	$main.show()
