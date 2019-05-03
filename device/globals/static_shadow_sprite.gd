extends Sprite

onready var character = get_parent()

var prev_scale_x

func _process(_delta):
	# Compensate for the character flipping
	if character.scale.x < 0 and character.scale.x != prev_scale_x:
		self.scale.x *= -1
		prev_scale_x = character.scale.x
	elif self.scale.x < 0 and character.scale.x > 0:
		self.scale.x *= -1
		prev_scale_x = character.scale.x

