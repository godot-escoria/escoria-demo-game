# Main_scene is the entry point for Godot Engine.
# This scene sets up the main menu scene to load.
extends Node
class_name ESCMain

var escoria_node: Escoria


# Start the main menu
func _ready():
	escoria.logger.info(self, "Escoria starts...")

	escoria_node = preload("res://addons/escoria-core/game/escoria.tscn").instance()
	add_child(escoria_node)

	if not escoria.is_direct_room_run:
		escoria_node.init()
