## Main_scene is the entry point for Godot Engine.
##
## This scene sets up the main scene to load.
extends Node
class_name ESCMain

## Reference to the Escoria node instance.
var escoria_node: Escoria


## Instanciate Escoria scene[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _ready():
	escoria.logger.info(self, "Escoria starts...")

	escoria_node = preload("res://addons/escoria-core/game/escoria.tscn").instantiate()
	add_child(escoria_node)

	if not escoria.is_direct_room_run:
		escoria_node.init()
