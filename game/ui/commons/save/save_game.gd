extends Control

signal back_button_pressed

export(PackedScene) var slot_ui_scene

var slot_pressed

func _ready():
	refresh_savegames()


func _on_slot_pressed(p_slot_n: int):
	slot_pressed = p_slot_n
	if escoria.save_manager.save_game_exists(p_slot_n):
		# TODO Manage save override, ask for confirmation
		pass
	else:
		$save_name_popup.popup()


func refresh_savegames():
	for slot in $ScrollContainer/slots.get_children():
		$ScrollContainer/slots.remove_child(slot)
	
	var saves_list = escoria.save_manager.get_saves_list()
	for i in saves_list.size():
		var save_data = saves_list[i+1]
		var new_slot = slot_ui_scene.instance()
		$ScrollContainer/slots.add_child(new_slot)
		new_slot.set_slot_name_date(save_data["name"], save_data["date"])
		new_slot.connect("pressed", self, "_on_slot_pressed", [i+1])
	
	var datetime = OS.get_datetime()
	var datetime_string = "%02d/%02d/%02d %02d:%02d" % [
		datetime["day"],
		datetime["month"],
		datetime["year"],
		datetime["hour"],
		datetime["minute"],
	]
	var new_slot = slot_ui_scene.instance()
	$ScrollContainer/slots.add_child(new_slot)
	new_slot.set_slot_name_date(tr("New save"), datetime_string)
	new_slot.connect("pressed", self, "_on_slot_pressed", [saves_list.size()+1])
		

func _on_back_pressed():
	emit_signal("back_button_pressed")


func _on_save_name_popup_savegame_name_ok(p_savename: String):
	escoria.save_manager.save_game(slot_pressed, p_savename)
	refresh_savegames()
	slot_pressed = null


func _on_save_name_popup_savegame_cancel():
	pass 
