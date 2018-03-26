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
	# Get mouse position, since event.position only works with Area2D exits
	var pos = get_viewport().get_mouse_position()

	if player and event.doubleclick:
		player.set_position(pos)
	elif player:
		# Control blocks input to background, so make player walk
		player.walk_to(pos)

func mouse_exit():
	vm.hover_end()
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", "")

func stopped_at(pos):
	if self is Control and get_global_rect().has_point(pos) and "exit" in game:
		vm.run_event(game["exit"])

func body_entered(body):
	if body is preload("res://globals/player.gd") and "exit" in game:
		vm.run_event(game["exit"])

func _ready():
	add_to_group("exit")

	var f = File.new()
	if f.file_exists(esc_script):
		game = vm.compile(esc_script)

	connect("body_entered", self, "body_entered")