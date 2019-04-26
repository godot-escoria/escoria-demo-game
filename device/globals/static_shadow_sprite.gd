extends Sprite

onready var character = get_parent()

func _process(_delta):
	# Compensate for the character flipping
	if character.scale.x < 0:
		self.scale.x *= -1

