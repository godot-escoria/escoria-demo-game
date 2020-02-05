extends Node


func dialog_confirmed():
	queue_free()

func _ready():
	# warning-ignore:return_value_discarded
	connect("confirmed", self, "dialog_confirmed")

