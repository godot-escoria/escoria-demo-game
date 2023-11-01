tool
extends Resource
class_name ESCMiscAnimationResource

# Name of the animation
export(String) var animation_name: String

# Array of Animations
export(Array, Resource) var animations = [] setget set_animations

func set_animations(p_set_animations: Array) -> void:
	animations = p_set_animations
	emit_changed()