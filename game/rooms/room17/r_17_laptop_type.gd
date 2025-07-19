extends Control



@onready var say_command: SayCommand = SayCommand.new()
@onready var acceptinput_command: AcceptInputCommand = AcceptInputCommand.new()



func _ready():
	acceptinput_command.run(["NONE"])


func _on_cancel_button_pressed():
	acceptinput_command.run(["ALL"])
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	queue_free()

func _on_ok_button_pressed():
	var text = $Panel/LineEdit.text
	queue_free()
	
	say_command.run(
		[
			"player",
			$Panel/LineEdit.text,
			"floating",
			""
		]
	)
	acceptinput_command.run(["ALL"])
	escoria.current_state = escoria.GAME_STATE.DEFAULT
