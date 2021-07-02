extends Panel

var numbers_array: Array
var next_to_be_pressed: int = 1

func _ready():
	randomize()
	
	initialize()
	reset()

	for button in $GridContainer.get_children():
		button.connect("pressed", self, "_button_pressed", [button])
	
	escoria.main.current_scene.game.hide_ui()
	escoria.main.current_scene.hide()
	

func initialize():
	numbers_array = range(1, 11)
	numbers_array.shuffle()
	
func reset():
	$win_label.hide()
	next_to_be_pressed = 1
	var i = 0
	for button in $GridContainer.get_children():
		var number = numbers_array[i]
		button.text = str(number)
		button.pressed = false
		button.disabled = false
		i += 1


func _button_pressed(button: Button):
	var number: String= button.text
	if int(number) != next_to_be_pressed:
		reset()
	else:
		button.disabled = true
		next_to_be_pressed += 1
	
	if next_to_be_pressed == 11:
		win()

func win():
	$win_label.show()
	yield(get_tree().create_timer(2), "timeout")
	hide()
	
	escoria.main.current_scene.game.show_ui()
	escoria.main.current_scene.show()
	escoria.globals_manager.set_global("r8_m_door_open", true)
	escoria.object_manager.get_object("r8_m_door").set_state("door_open")


func _on_quit_pressed():
	escoria.main.current_scene.game.show_ui()
	escoria.main.current_scene.show()
	queue_free()
