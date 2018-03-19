extends "res://globals/hotspot.gd"

func get_tooltip():
	if TranslationServer.get_locale() == ProjectSettings.get_setting("escoria/application/tooltip_lang_default"):
		return tooltip
	else:
		if tr(tooltip) == tooltip:
			return global_id+".tooltip"
		else:
			return tooltip

func mouse_enter():
	vm.hover_begin(self)
	var tt = get_tooltip()
	var text = tr(tt)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", text)

func input(event):
	if !(event is InputEventMouseButton and event.is_pressed()):
		return

	var player = vm.get_object("player")
	if player and event.doubleclick:
		# event.position only works with Area2D exits
		#player.set_position(event.position)
		var pos = get_viewport().get_mouse_position()
		player.set_position(pos)

func exit(body):
	printt("EXITING", body, body.get_name())

func mouse_exit():
	vm.hover_end()
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", "")

func _ready():
	connect("body_entered", self, "exit")