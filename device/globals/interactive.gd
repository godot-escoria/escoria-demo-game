extends Node2D

#warning-ignore:unused_class_variable
export var global_id = ""                                  # API property
#warning-ignore:unused_class_variable
export(String, FILE, ".esc") var events_path = ""          # API property
export var active = true setget set_active,get_active

var event_table = {}

# This'll contain a highlight tooltip if `tooltip_pos` is set as a child
var highlight_tooltip

var width = float(ProjectSettings.get("display/window/size/width"))
var height = float(ProjectSettings.get("display/window/size/height"))

func show_highlight():
	if not self.visible:
		return

	# This is essentially is_interactive, but triggers and exit don't have separate areas
	if "area" in self and self.area and not self.area.visible:
		return

	if not has_node("tooltip_pos"):
		return

	highlight_tooltip = vm.tooltip.duplicate()
	assert highlight_tooltip != vm.tooltip

	var tt_pos = $"tooltip_pos".global_position
	var tt_text = get_tooltip()

	highlight_tooltip.highlight_only = true
	highlight_tooltip.follow_mouse = false
	highlight_tooltip.text = tt_text

	tt_pos = vm.camera.zoom_transform.xform(tt_pos)

	# Bail out if we're hopelessly out-of-view
	if tt_pos.x < 0 or tt_pos.x > width or tt_pos.y < 0 or tt_pos.y > height:
		highlight_tooltip.free()
		highlight_tooltip = null
		return

	vm.tooltip.get_parent().add_child(highlight_tooltip)

	highlight_tooltip.set_position(tt_pos)

	highlight_tooltip.show()

func hide_highlight():
	if not highlight_tooltip:
		return

	assert highlight_tooltip.visible

	highlight_tooltip.hide()
	highlight_tooltip.free()
	highlight_tooltip = null

func run_event(p_ev):
	vm.emit_signal("run_event", p_ev)

func activate(p_action, p_param = null):
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

func set_interactive(p_interactive):
	self.area.visible = p_interactive

func get_active():
	return active

func _ready():
	add_to_group("highlight_tooltip")

