extends Control

signal back_button_pressed

export(PackedScene) var slot_ui_scene

func _ready():
	refresh_savegames()

func _on_slot_pressed(slot_id: int) -> void:
	escoria.save_manager.load_game(slot_id)

func _on_back_pressed():
	emit_signal("back_button_pressed")

func refresh_savegames():
	for slot in $CenterContainer/VBoxContainer/\
			ScrollContainer/slots.get_children():
		$CenterContainer/VBoxContainer/\
				ScrollContainer/slots.remove_child(slot)
	
	var saves_list = escoria.save_manager.get_saves_list()
	for i in saves_list.size():
		var save_data = saves_list[i+1]
		var new_slot = slot_ui_scene.instance()
		$CenterContainer/VBoxContainer/ScrollContainer/slots.add_child(
			new_slot
		)
		new_slot.set_slot_name_date(save_data["name"], save_data["date"])
		new_slot.connect("pressed", self, "_on_slot_pressed", [i+1])
