extends PopupDialog

signal savegame_name_ok(savegame_name)
signal savegame_cancel

func _on_cancel_pressed():
	emit_signal("savegame_cancel")
	hide()

func _on_ok_pressed():
	if not $MarginContainer/VBoxContainer/LineEdit.text.empty():
		emit_signal("savegame_name_ok", $MarginContainer/VBoxContainer/LineEdit.text)
		$MarginContainer/VBoxContainer/LineEdit.clear()
		hide()
