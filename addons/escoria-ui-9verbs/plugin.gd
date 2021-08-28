# Plugin script to initialize Escoria simple mouse UI
tool
extends EditorPlugin


# Setup Escoria
func _enter_tree():
	ProjectSettings.set_setting("escoria/ui/tooltip_follows_mouse", false)
	ProjectSettings.set_setting("escoria/ui/game_scene", "res://addons/escoria-ui-9verbs/game.tscn")
