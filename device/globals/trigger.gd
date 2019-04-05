extends "res://globals/interactive.gd"

signal mouse_enter_trigger
signal mouse_exit_trigger

export var tooltip = ""

func get_tooltip(hint=null):
	if TranslationServer.get_locale() == ProjectSettings.get_setting("escoria/platform/development_lang"):
		if not global_id and ProjectSettings.get_setting("escoria/platform/force_tooltip_global_id"):
			vm.report_errors("exit", ["Missing global_id in exit with tooltip '" + tooltip + "'"])
		return tooltip

	var tooltip_identifier = global_id + ".tooltip"
	if hint:
		tooltip_identifier += "." + hint

	var translated = tr(tooltip_identifier)

	# Try again if there's no translation for this hint
	if translated == "\"":
		tooltip_identifier = global_id + ".tooltip"
		translated = tr(tooltip_identifier)

	if translated == tooltip_identifier:
		if not global_id and ProjectSettings.get_setting("escoria/platform/force_tooltip_global_id"):
			vm.report_errors("exit", ["Missing global_id in exit with tooltip '" + tooltip + "'"])
		return tooltip_identifier

	return translated

func mouse_enter():
	emit_signal("mouse_enter_trigger", self)

func mouse_exit():
	emit_signal("mouse_exit_trigger", self)

func area_input(_viewport, event, _shape_idx):
	input(event)

func input(event):
	if !(event is InputEventMouseButton and event.is_pressed()):
		return

	if vm.accept_input != vm.acceptable_inputs.INPUT_ALL:
		return

	# Do not allow input on triggers/exits with inventory open
	if vm.inventory and vm.inventory.blocks_tooltip():
		return

	if vm.action_menu and vm.action_menu.is_visible():
		vm.action_menu.stop()

	var player = vm.get_object("player")
	# Get mouse position, since event.position only works with Area2D exits
	var pos = get_global_mouse_position()

	# Disallow doubleclick teleportation if there's no tooltip.
	if player and event.doubleclick and self.tooltip:
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
	var conn_err

	var area
	if has_node("area"):
		area = get_node("area")
	else:
		area = self

	if ClassDB.class_has_signal(area.get_class(), "input_event"):
		conn_err = area.connect("input_event", self, "area_input")
		if conn_err:
			vm.report_errors("item", ["area.input_event -> area_input error: " + String(conn_err)])

	elif ClassDB.class_has_signal(area.get_class(), "gui_input"):
		conn_err = area.connect("gui_input", self, "input")
		if conn_err:
			vm.report_errors("item", ["area.gui_input -> gui_input error: " + String(conn_err)])

	else:
		vm.report_errors("trigger", ["No input events possible for global_id " + global_id])

	if events_path:
		var f = File.new()
		if f.file_exists(events_path):
			event_table = vm.compile(events_path)

	if ClassDB.class_has_signal(area.get_class(), "mouse_entered"):
		conn_err = area.connect("mouse_entered", self, "mouse_enter")
		if conn_err:
			vm.report_errors("item", ["area.mouse_entered -> mouse_enter error: " + String(conn_err)])

		conn_err = area.connect("mouse_exited", self, "mouse_exit")
		if conn_err:
			vm.report_errors("item", ["area.mouse_exited -> mouse_exit error: " + String(conn_err)])

	conn_err = connect("body_entered", self, "body_entered")
	if conn_err:
		vm.report_errors("item", ["area.body_entered -> body_entered error: " + String(conn_err)])

	conn_err = connect("body_exited", self, "body_exited")
	if conn_err:
		vm.report_errors("item", ["area.body_exited -> body_exited error: " + String(conn_err)])

	conn_err = connect("mouse_enter_trigger", $"/root/scene/game", "ev_mouse_enter_trigger")
	if conn_err:
		vm.report_errors("item", ["mouse_enter_trigger -> ev_mouse_enter_trigger error: " + String(conn_err)])

	conn_err = connect("mouse_exit_trigger", $"/root/scene/game", "ev_mouse_exit_trigger")
	if conn_err:
		vm.report_errors("item", ["mouse_exit_trigger -> ev_mouse_exit_trigger error: " + String(conn_err)])

	vm.register_object(global_id, self)

