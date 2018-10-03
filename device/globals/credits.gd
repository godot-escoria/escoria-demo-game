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

func _ready():
	main.menu_open(self)

	$"menu".connect("pressed", self, "back_pressed")

