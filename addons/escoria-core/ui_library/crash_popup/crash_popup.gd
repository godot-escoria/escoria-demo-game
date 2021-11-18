extends AcceptDialog

func _ready():
	popup_exclusive = true
	pause_mode = Node.PAUSE_MODE_PROCESS

func set_message(p_message: String):
	$MarginContainer/message.text = tr(p_message)
