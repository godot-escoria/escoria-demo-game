

func dialog_confirmed():
	queue_free()

func _ready():
	connect("confirmed", self, "dialog_confirmed")
