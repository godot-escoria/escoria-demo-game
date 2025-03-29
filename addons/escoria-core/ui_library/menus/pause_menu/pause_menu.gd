# A menu shown in game
extends Control


# Make the pause menu process in pause mode and hide it just to be sure
func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


# Continue the game
func _on_continue_pressed():
	escoria.main.current_scene.game.unpause_game()


# Show the save slots
func _on_save_game_pressed():
	$VBoxContainer.hide()
	$save_game.refresh_savegames()
	$save_game.show()


# Show the load slots
func _on_load_game_pressed():
	$VBoxContainer.hide()
	$load_game.refresh_savegames()
	$load_game.show()


# Show the options menu
func _on_options_pressed():
	$VBoxContainer.hide()
	$options.show()


# Quit the game
func _on_quit_pressed():
	escoria.quit()


# Hide the save slots after clicking back button
func _on_save_game_back_button_pressed():
	reset()


# Hide the load slots after clicking back button
func _on_load_game_back_button_pressed():
	reset()


# Hide options menu after clicking back button
func _on_options_back_button_pressed():
	reset()


# Set whether saving is enabled currently
#
# #### Parameters
# - p_enabled: Enable or disable saving
func set_save_enabled(p_enabled: bool):
	$VBoxContainer/menuitems/save_game.disabled = !p_enabled


# Resets the UI to initial state
func reset():
	$save_game.hide()
	$load_game.hide()
	$options.hide()
	$VBoxContainer.show()


func _on_new_game_pressed():
	#yield(escoria.new_game(), "completed")
	escoria.new_game()
	escoria.main.current_scene.game.unpause_game()
