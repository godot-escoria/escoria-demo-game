extends Control

var showed: bool = false

func _ready():
	pass


func _on_inventory_button_pressed():
	if !$AnimationPlayer.is_playing() and !showed:
		show_inventory()
	elif !$AnimationPlayer.is_playing() and showed:
		close_inventory()
		

func show_inventory():
	$AnimationPlayer.play("show")
	yield($AnimationPlayer, "animation_finished")
	showed = true


func close_inventory():
	$AnimationPlayer.play("hide")
	yield($AnimationPlayer, "animation_finished")
	showed = false
