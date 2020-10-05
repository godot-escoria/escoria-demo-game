extends "res://globals/interactive.gd"

signal left_click_on_trigger
signal left_dblclick_on_trigger
signal right_click_on_trigger
signal mouse_enter_trigger
signal mouse_exit_trigger

export var tooltip = ""
export var dblclick_teleport = true

# Superior doubleclick
var last_lmb_dt = 0
var waiting_dblclick = false

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
	if !(event is InputEventMouseButton and event.is_pressed()):
		return

	var ev_pos = get_global_mouse_position()
	if event.is_action("game_general"):
		if last_lmb_dt <= vm.DOUBLECLICK_TIMEOUT:
			emit_signal("left_dblclick_on_trigger", self, ev_pos, event)
			last_lmb_dt = 0
			waiting_dblclick = null
		else:
			last_lmb_dt = 0
			waiting_dblclick = [ev_pos, event]
	elif event.is_action("game_rmb"):
		emit_signal("right_click_on_trigger", self, ev_pos, event)

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

func _physics_process(dt):
	last_lmb_dt += dt

	if waiting_dblclick and last_lmb_dt > vm.DOUBLECLICK_TIMEOUT:
		emit_signal("left_click_on_trigger", self, waiting_dblclick[0], waiting_dblclick[1])
		last_lmb_dt = 0
		waiting_dblclick = null

func _ready():
	var conn_err

	#assert(self is Area2D)

	conn_err = connect("input_event", self, "area_input")
	if conn_err:
		vm.report_errors("trigger", ["trigger.input_event -> area_input error: " + String(conn_err)])

	if events_path:
		var f = File.new()
		if f.file_exists(events_path):
			event_table = vm.compile(events_path)

	conn_err = connect("left_click_on_trigger", $"/root/scene/game", "ev_left_click_on_trigger")
	if conn_err:
		vm.report_errors("trigger", ["left_click_on_trigger -> ev_left_click_on_trigger error: " + String(conn_err)])

	conn_err = connect("left_dblclick_on_trigger", $"/root/scene/game", "ev_left_dblclick_on_trigger")
	if conn_err:
		vm.report_errors("trigger", ["left_dblclick_on_trigger -> ev_left_dblclick_on_trigger error: " + String(conn_err)])

	conn_err = connect("mouse_entered", self, "mouse_enter")
	if conn_err:
		vm.report_errors("trigger", ["trigger.mouse_entered -> mouse_enter error: " + String(conn_err)])

	conn_err = connect("mouse_exited", self, "mouse_exit")
	if conn_err:
		vm.report_errors("trigger", ["trigger.mouse_exited -> mouse_exit error: " + String(conn_err)])

	conn_err = connect("body_entered", self, "body_entered")
	if conn_err:
		vm.report_errors("trigger", ["trigger.body_entered -> body_entered error: " + String(conn_err)])

	conn_err = connect("body_exited", self, "body_exited")
	if conn_err:
		vm.report_errors("trigger", ["trigger.body_exited -> body_exited error: " + String(conn_err)])

	conn_err = connect("mouse_enter_trigger", $"/root/scene/game", "ev_mouse_enter_trigger")
	if conn_err:
		vm.report_errors("trigger", ["mouse_enter_trigger -> ev_mouse_enter_trigger error: " + String(conn_err)])

	conn_err = connect("mouse_exit_trigger", $"/root/scene/game", "ev_mouse_exit_trigger")
	if conn_err:
		vm.report_errors("trigger", ["mouse_exit_trigger -> ev_mouse_exit_trigger error: " + String(conn_err)])

	vm.register_object(global_id, self)

	add_to_group("triggers")

