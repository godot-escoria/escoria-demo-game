extends "res://globals/scene_base.gd"

func show_credits():
	get_node("/root/main").load_menu(Globals.get("ui/credits"))

func _ready():
	get_node("/root/main").load_menu(Globals.get("ui/main_menu"))
