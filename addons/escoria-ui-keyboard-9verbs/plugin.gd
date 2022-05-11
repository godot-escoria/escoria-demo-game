# Plugin script to initialize Escoria 9-verbs with keyboard plugin
tool
extends EditorPlugin


# Deregister UI
func disable_plugin() -> void:
	print("Disabling plugin Escoria UI 9-verbs with keyboard")
	EscoriaPlugin.deregister_ui("res://addons/escoria-ui-keyboard-9verbs/game.tscn")


# Register UI with Escoria
func enable_plugin():
	print("Enabling plugin Escoria UI 9-verbs with keyboard")
	EscoriaPlugin.register_ui("res://addons/escoria-ui-keyboard-9verbs/game.tscn")
