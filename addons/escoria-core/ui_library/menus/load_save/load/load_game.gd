# A container for loading from a save slot
extends Control


# Emitted when the back button is pressed
signal back_button_pressed

# Emitted when a game slot is pressed
signal load_slot_button_pressed

# The scene to display a slot
export(PackedScene) var slot_ui_scene


# Load the savegames when loaded
func _ready():
	refresh_savegames()


# A slot was pressed. Load the game
#
# #### Parameters
# - slot_id: The slot that was pressed
func _on_slot_pressed(slot_id: int) -> void:
	escoria.save_manager.load_game(slot_id)
	emit_signal("load_slot_button_pressed")


# The back button was pressed
func _on_back_pressed():
	emit_signal("back_button_pressed")


# Create the slots from the list of savegames
func refresh_savegames():
	for slot in $VBoxContainer/ScrollContainer/slots.get_children():
		$VBoxContainer/ScrollContainer/slots.remove_child(slot)
	
	var saves_list = escoria.save_manager.get_saves_list()
	for i in saves_list.size():
		var save_data = saves_list[i+1]
		var new_slot = slot_ui_scene.instance()
		$VBoxContainer/ScrollContainer/slots.add_child(
			new_slot
		)
		new_slot.set_slot_name_date(save_data["name"], save_data["date"])
		new_slot.connect("pressed", self, "_on_slot_pressed", [i+1])
