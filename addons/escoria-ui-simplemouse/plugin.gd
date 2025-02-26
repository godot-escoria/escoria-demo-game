@tool
# Plugin script to initialize Escoria simple mouse UI
extends EditorPlugin


# Override function to return the plugin name.
func _get_plugin_name():
	return "escoria-ui-simplemouse"


# Deregister UI
func _disable_plugin():
	print("Disabling plugin Escoria UI Simple Mouse.")
	EscoriaPlugin.deregister_ui("res://addons/escoria-ui-simplemouse/game.tscn")


# Register UI with Escoria
func _enable_plugin():
	print("Enabling plugin Escoria UI Simple Mouse.")
	if not EscoriaPlugin.register_ui(self, "res://addons/escoria-ui-simplemouse/game.tscn"):
		get_editor_interface().set_plugin_enabled(
			_get_plugin_name(),
			false
		)
