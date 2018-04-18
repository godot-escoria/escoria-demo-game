extends "res://globals/hotspot.gd"

func get_tooltip():
	if TranslationServer.get_locale() == ProjectSettings.get_setting("escoria/application/development_lang"):
		return tooltip
	else:
		if tr(tooltip) == tooltip:
			return global_id + ".tooltip"
		else:
			return tooltip

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

func mouse_enter():
	vm.hover_begin(self)
	var tt = get_tooltip()
	var text = tr(tt)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", text)

func mouse_exit():
	vm.hover_end()
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", "")

func stopped_at(pos):
	if self is Control and get_global_rect().has_point(pos):
		run_event("enter")

func body_entered(body):
	if body is preload("res://globals/player.gd"):
		run_event("enter")

func body_exited(body):
	if body is preload("res://globals/player.gd"):
		run_event("exit")

func run_event(event):
	if event in event_table:
		vm.run_event(event_table[event])

func _ready():
	add_to_group("exit")
	connect("body_entered", self, "body_entered")
	connect("body_exited", self, "body_exited")
	