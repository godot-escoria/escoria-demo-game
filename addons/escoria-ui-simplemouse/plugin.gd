# Plugin script to initialize Escoria simple mouse UI
tool
extends EditorPlugin


# Deregister UI
func disable_plugin():
	print("Disabling plugin Escoria UI Simple Mouse")
	EscoriaPlugin.deregister_ui("res://addons/escoria-ui-simplemouse/game.tscn")


# Register UI with Escoria
func enable_plugin():
	print("Enabling plugin Escoria UI Simple Mouse")
	EscoriaPlugin.register_ui("res://addons/escoria-ui-simplemouse/game.tscn")
