extends "res://globals/interactive.gd"

export(String, FILE, ".esc") var events_path
export var global_id = ""
export var tooltip = ""

var event_table = {}

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
	vm.hover_begin(self)
	var tt = get_tooltip()
	var text = tr(tt)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", text)

func mouse_exit():
	vm.hover_end()
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", "")

func area_input(viewport, event, shape_idx):
	input(event)

func input(event):
	if !(event is InputEventMouseButton and event.is_pressed()):
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
	if area is Area2D:
		area.connect("input_event", self, "area_input")
	else:
		area.connect("gui_input", self, "input")

	if events_path:
		var f = File.new()
		if f.file_exists(events_path):
			event_table = vm.compile(events_path)

	vm.register_object(global_id, self)

	area.connect("mouse_entered", self, "mouse_enter")
	area.connect("mouse_exited", self, "mouse_exit")

	connect("body_entered", self, "body_entered")
	connect("body_exited", self, "body_exited")

