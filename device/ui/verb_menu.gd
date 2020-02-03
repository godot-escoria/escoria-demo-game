extends Control

var vm

var act_buttons = []

func action_changed(action):
	get_tree().call_group("game", "set_current_action", action)

	for b in act_buttons:
		b.set_pressed(b.get_name() == action)

func _ready():

	vm = get_node("/root/vm")

	var acts = get_node("actions")
	for i in range(acts.get_child_count()):
		var c = acts.get_child(i)
		if !(c is BaseButton):
			continue

		c.connect("pressed", self, "action_changed", [c.get_name()])
		act_buttons.push_back(c)


