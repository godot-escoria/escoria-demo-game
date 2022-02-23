# Plugin script to initialize Escoria simple mouse UI
tool
extends EditorPlugin


# Register UI
func _enter_tree() -> void:
	call_deferred("_register")


# Deregister UI
func _exit_tree() -> void:
	escoria.deregister_ui("res://addons/escoria-ui-keyboard-9verbs/game.tscn")


# Register UI with Escoria
func _register():
	escoria.register_ui("res://addons/escoria-ui-keyboard-9verbs/game.tscn")
