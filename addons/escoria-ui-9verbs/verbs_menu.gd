extends Control

"""
This script is out of Escoria's scope. It controls the UI reaction to an
UI event (eg right click) to change the cursor accordingly.
"""

var selected_action

func _ready():
	for but in get_children():
		but.connect("pressed", self, "_on_action_selected", [but.name])
		but.toggle_mode = true

func _on_action_selected(action: String):
	if escoria.inputs_manager.input_mode != escoria.inputs_manager.INPUT_ALL:
		unselect_actions()
		return

	escoria.action_manager.set_current_action(action)

	for but in get_children():
		but.set_pressed(but.get_name() == action)

func unselect_actions():
	for but in get_children():
		but.set_pressed(false)

func set_by_name(action_name: String):
	selected_action = action_name
	for but in get_children():
		but.set_pressed(but.get_name() == action_name)
