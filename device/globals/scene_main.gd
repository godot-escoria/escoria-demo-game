extends "res://globals/scene_base.gd"

func show_credits():
	main.load_menu(ProjectSettings.get_setting("ui/credits"))

func _ready():
	main.load_menu(ProjectSettings.get_setting("ui/main_menu"))
