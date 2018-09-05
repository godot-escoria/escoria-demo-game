extends "res://globals/scene_base.gd"

func show_credits(end=false):
	var credits

	if not end:
		credits = ProjectSettings.get_setting("escoria/ui/credits")
	else:
		credits = ProjectSettings.get_setting("escoria/ui/end_credits")

	main.load_menu(credits)

func _ready():
	main.load_menu(ProjectSettings.get_setting("escoria/ui/main_menu"))
