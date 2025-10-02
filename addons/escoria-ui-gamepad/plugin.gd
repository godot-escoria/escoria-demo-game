@tool
# Plugin script to initialize Escoria simple mouse UI
extends EditorPlugin


# Override function to return the plugin name.
func _get_plugin_name():
	return "escoria-ui-gamepad"


# Deregister UI
func _disable_plugin():
	print("Disabling plugin Escoria UI Gamepad.")
	EscoriaPlugin.deregister_ui("res://addons/escoria-ui-gamepad/game.tscn")


# Register UI with Escoria
func _enable_plugin():
	print("Enabling plugin Escoria UI Gamepad.")
	if not EscoriaPlugin.register_ui(self, "res://addons/escoria-ui-gamepad/game.tscn"):
		get_editor_interface().set_plugin_enabled(
			_get_plugin_name(),
			false
		)
