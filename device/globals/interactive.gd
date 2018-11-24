extends Node2D

export var global_id = ""
export(String, FILE, ".esc") var events_path = ""
export var active = true setget set_active,get_active

var event_table = {}

func run_event(p_ev):
	vm.emit_signal("run_event", p_ev)

func activate(p_action, p_param = null, p_flags = null):
	if p_param != null:
		p_action = p_action + " " + p_param.global_id

	if p_action in event_table:
		run_event(event_table[p_action])
	else:
		return false
	return true

func set_active(p_active):
	active = p_active
	if p_active:
		show()
	else:
		hide()

func get_active():
	return active

