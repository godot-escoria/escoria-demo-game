extends "res://globals/scene_base.gd"

func show_credits():
	get_node("/root/main").load_menu(ProjectSettings.get("ui/credits"))

func _ready():
	get_node("/root/main").load_menu(ProjectSettings.get("ui/main_menu"))

