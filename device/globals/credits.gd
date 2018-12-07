extends Control

func close():
	main.menu_close(self)
	queue_free()

func menu_collapsed():
	close()

func input(event):
	if event.is_action("menu_request") && event.is_pressed() && !event.is_echo():
		close()

func back_pressed():
	close()

func _find_menu_buttons(node=self):
	for c in node.get_children():
		if c is preload("res://ui/menu_button.gd") or c is preload("res://ui/menu_texturebutton.gd"):
			var sighandler_name = c.name + "_pressed"

			c.connect("pressed", self, sighandler_name)
		else:
			_find_menu_buttons(c)

func _ready():
	_find_menu_buttons()

	add_to_group("ui")

	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "ui", "language_changed")

	main.menu_open(self)

