extends "res://globals/scene_base.gd"

func show_credits():
	main.load_menu(ProjectSettings.get("ui/credits"))

func _ready():
	main.load_menu(ProjectSettings.get("ui/main_menu"))
