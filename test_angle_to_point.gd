extends Node


func _ready():
	var pos0 = Vector2(0,0)
	var pos1 = Vector2(10,0)
	
	printt("angle_to_point ", pos0, " ", pos1, " ", pos0.angle_to_point(pos1))

