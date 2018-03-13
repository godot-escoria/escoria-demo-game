extends "res://globals/interactive.gd"

export(String, FILE, ".esc") var esc_script  # must contain :dblclick
export var global_id = ""
export var tooltip = ""

var event_table = {}

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

func mouse_clicked(event):
	if !(event is InputEventMouseButton):
		return

	if event.doubleclick:
		vm.run_event(event_table["dblclick"])

func mouse_exit():
	vm.hover_end()
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "hud", "set_tooltip", "")

func _ready():
	if esc_script != "":
		event_table = vm.compile(esc_script)
		if !("dblclick" in event_table):
			vm.report_errors(esc_script, ["Missing :dblclick"])

	self.connect("mouse_entered", self, "mouse_enter")
	self.connect("gui_input", self, "mouse_clicked")
	self.connect("mouse_exited", self, "mouse_exit")

