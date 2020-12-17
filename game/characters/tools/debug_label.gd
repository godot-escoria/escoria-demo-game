extends Label

func _ready():
	var scale = get_parent().get_scale()
	self.set_scale(Vector2(1/scale.x, 1/scale.y)) #2D
