extends PopupDialog

signal confirm_yes

func _on_no_pressed():
	hide()


func _on_yes_pressed():
	emit_signal("confirm_yes")
	hide()

