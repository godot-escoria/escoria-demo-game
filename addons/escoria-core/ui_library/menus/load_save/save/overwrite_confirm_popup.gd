extends Popup

signal confirm_yes

func _ready():
	$MarginContainer/VBoxContainer/HBoxContainer/yes.grab_focus()

func _on_no_pressed():
	hide()


func _on_yes_pressed():
	confirm_yes.emit()
	hide()
