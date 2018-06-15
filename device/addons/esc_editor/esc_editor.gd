tool
extends EditorPlugin

var vbox

func _enter_tree():
	vbox = preload('res://addons/esc_editor/vbox.tscn').instance()
	add_control_to_bottom_panel(vbox,"esc_editor")
func _exit_tree():
	remove_control_from_bottom_panel(vbox)
	vbox = null
