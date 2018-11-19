extends "res://globals/interactive.gd"

export(String, FILE, ".esc") var events_path
export var global_id = ""
export var tooltip = ""

var event_table = {}
var hud
var inventory

func get_tooltip():
	if TranslationServer.get_locale() == ProjectSettings.get_setting("escoria/platform/development_lang"):
		if not global_id and ProjectSettings.get_setting("escoria/platform/force_tooltip_global_id"):
			vm.report_errors("exit", ["Missing global_id in exit with tooltip '" + tooltip + "'"])
		return tooltip

	var tooltip_identifier = global_id + ".tooltip"
	var translated = tr(tooltip_identifier)

	if translated == tooltip_identifier:
		if not global_id and ProjectSettings.get_setting("escoria/platform/force_tooltip_global_id"):
			vm.report_errors("exit", ["Missing global_id in exit with tooltip '" + tooltip + "'"])
		return tooltip_identifier

	return translated

func mouse_enter():
	get_tree().call_group("game", "mouse_enter", self)

func mouse_exit():
	get_tree().call_group("game", "mouse_exit", self)

func area_input(viewport, event, shape_idx):
	input(event)

func input(event):
	if !(event is InputEventMouseButton and event.is_pressed()):
		return

	# Do not allow input on triggers/exits with inventory open
	hud = $"/root/scene/game/hud_layer/hud"

	if hud.has_node("inventory"):
		inventory = hud.get_node("inventory")

	if inventory and inventory.blocks_tooltip():
		return

	var player = vm.get_object("player")
	# Get mouse position, since event.position only works with Area2D exits
	var pos = get_global_mouse_position()

	if player and event.doubleclick:
		player.set_position(pos)
	elif player:
		# Control blocks input to background, so make player walk
		player.walk_to(pos)

func body_entered(body):
	if body is esc_type.PLAYER:
		if self.visible:
			run_event("enter")

func body_exited(body):
	if body is esc_type.PLAYER:
		if self.visible:
			run_event("exit")

func run_event(event):
	if event in event_table:
		vm.run_event(event_table[event])

func set_active(p_active):
	self.visible = p_active

func _ready():
	var area
	if has_node("area"):
		area = get_node("area")
	else:
		area = self

	if ClassDB.class_has_signal(area.get_class(), "input_event"):
		area.connect("input_event", self, "area_input")
	elif ClassDB.class_has_signal(area.get_class(), "gui_input"):
		area.connect("gui_input", self, "input")
	else:
		vm.report_errors("trigger", ["No input events possible for global_id " + global_id])

	if events_path:
		var f = File.new()
		if f.file_exists(events_path):
			event_table = vm.compile(events_path)

	if ClassDB.class_has_signal(area.get_class(), "mouse_entered"):
		area.connect("mouse_entered", self, "mouse_enter")
		area.connect("mouse_exited", self, "mouse_exit")

	vm.register_object(global_id, self)

	connect("body_entered", self, "body_entered")
	connect("body_exited", self, "body_exited")

