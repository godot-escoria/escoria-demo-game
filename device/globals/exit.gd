extends "res://globals/hotspot.gd"

var game

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
	var pos = get_viewport().get_mouse_position()

	if player and event.doubleclick:
		# event.position only works with Area2D exits
		#player.set_position(event.position)
		player.set_position(pos)
	elif player:
		# Control blocks input to background, so make player walk
		player.walk_to(pos)

func mouse_exit():
	vm.hover_end()
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", "")

func stopped_at(pos):
	if self is Control:
		if get_global_rect().has_point(pos) and "exit" in game:
			vm.run_event(game["exit"])
	if self is Area2D:
		pass
		#var obj = shape_owner_get_shape(0, 0)
		#var p_intersect_point = obj.intersect_point(pos)
		#printt("HAS POINT", obj.points.size())

func _ready():
	add_to_group("exit")

	var f = File.new()
	if f.file_exists(esc_script):
		game = vm.compile(esc_script)
