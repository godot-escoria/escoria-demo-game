# Plugin script to initialize Escoria 9-verbs with keyboard plugin
tool
extends EditorPlugin


# Override function to return the plugin name.
func get_plugin_name():
	return "escoria-ui-keyboard-9verbs"


# Deregister UI
func disable_plugin() -> void:
	print("Disabling plugin Escoria UI 9-verbs with keyboard.")
	EscoriaPlugin.deregister_ui("res://addons/escoria-ui-keyboard-9verbs/game.tscn")


# Register UI with Escoria
func enable_plugin():
	print("Enabling plugin Escoria UI 9-verbs with keyboard.")
	if not EscoriaPlugin.register_ui("res://addons/escoria-ui-keyboard-9verbs/game.tscn"):
		get_editor_interface().set_plugin_enabled(
			get_plugin_name(),
			false
		)
