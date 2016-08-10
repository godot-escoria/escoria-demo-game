extends "res://game/globals/scene_base.gd"

func show_credits():
	get_node("/root/main").call_deferred("load_menu", "res://game/ui/credits/credits_main_menu.scn")

func _ready():
	get_node("/root/main").load_menu("res://game/ui/main_menu.xml")
