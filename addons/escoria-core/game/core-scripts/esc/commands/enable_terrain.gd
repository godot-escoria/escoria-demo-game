## `enable_terrain node_name`[br]
## [br]
## Enables the `ESCTerrain`'s `NavigationPolygonInstance` specified by the given
## node name. It will also disable the previously-activated
## `NavigationPolygonInstance`.[br]
## Use this to change where the player can walk, allowing them to walk into the
## next room once a door has been opened, for example.[br]
## [br]
## #### Parameters[br]
## [br]
## - *node_name*: Name of the `NavigationPolygonInstance` node to activate[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name EnableTerrainCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING],
		[null]
	)


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	var name: String = command_params[0]
	if escoria.room_terrain.has_node(name):
		var new_active_navigation_instance = \
				escoria.room_terrain.get_node(name)
		escoria.room_terrain.current_active_navigation_instance.enabled = false
		escoria.room_terrain.current_active_navigation_instance = \
				new_active_navigation_instance
		escoria.room_terrain.current_active_navigation_instance.enabled = true
		return ESCExecution.RC_OK
	else:
		raise_error(self, "Can not find terrain node. Terrain node %s could not be found." % name)
		return ESCExecution.RC_ERROR


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
