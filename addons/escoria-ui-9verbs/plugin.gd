# Plugin script to initialize Escoria simple mouse UI
tool
extends EditorPlugin


# Deregister UI
func disable_plugin():
	print("Disabling plugin Escoria UI 9-verbs.")
	EscoriaPlugin.deregister_ui("res://addons/escoria-ui-9verbs/game.tscn")


# Register UI with Escoria
func enable_plugin():
	print("Enabling plugin Escoria UI 9-verbs.")
	EscoriaPlugin.register_ui("res://addons/escoria-ui-9verbs/game.tscn")
