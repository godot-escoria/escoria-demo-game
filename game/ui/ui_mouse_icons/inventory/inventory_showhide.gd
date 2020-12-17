extends Control

var showed : bool = false

func _ready():
	pass



func _on_inventory_button_pressed():
	if !$AnimationPlayer.is_playing() and !showed:
		$AnimationPlayer.play("show")
		yield($AnimationPlayer, "animation_finished")
		showed = true
	elif !$AnimationPlayer.is_playing() and showed:
		$AnimationPlayer.play("hide")
		yield($AnimationPlayer, "animation_finished")
		showed = false
