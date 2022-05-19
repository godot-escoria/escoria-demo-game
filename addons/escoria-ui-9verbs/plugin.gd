# Plugin script to initialize Escoria simple mouse UI
tool
extends EditorPlugin


# Override function to return the plugin name.
func get_plugin_name():
	return "escoria-ui-9verbs"


# Deregister UI
func disable_plugin():
	print("Disabling plugin Escoria UI 9-verbs.")
	EscoriaPlugin.deregister_ui("res://addons/escoria-ui-9verbs/game.tscn")


# Register UI with Escoria
func enable_plugin():
	print("Enabling plugin Escoria UI 9-verbs.")
	if not EscoriaPlugin.register_ui(self, "res://addons/escoria-ui-9verbs/game.tscn"):
		get_editor_interface().set_plugin_enabled(
			get_plugin_name(),
			false
		)
