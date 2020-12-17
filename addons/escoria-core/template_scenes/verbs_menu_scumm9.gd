tool
extends Control

func _ready():
	for but in $actions.get_children():
		but.connect("pressed", self, "_on_action_selected", [but.name])
		but.toggle_mode = true

func _on_action_selected(action : String):
	escoria.set_current_action(action)

	for but in $actions.get_children():
		but.set_pressed(but.get_name() == action)
	
