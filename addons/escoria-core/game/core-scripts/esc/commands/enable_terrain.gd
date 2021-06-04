# `enable_terrain node_name`
# Enable the ESCTerrain's NavigationPolygonInstance defined by given node name. 
# Disables previously activated NavigationPolygonInstance.
# @ESC
extends ESCBaseCommand
class_name EnableTerrainCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_STRING],
		[null]
	)


# Run the command
func run(command_params: Array) -> int:
	var name : String = command_params[0]
	if escoria.room_terrain.has_node(name):
		var new_active_navigation_instance = \
				escoria.room_terrain.get_node(name)
		escoria.room_terrain.current_active_navigation_instance.enabled = false
		escoria.room_terrain.current_active_navigation_instance = \
				new_active_navigation_instance
		escoria.room_terrain.current_active_navigation_instance.enabled = true
		return ESCExecution.RC_OK
	else:
		escoria.logger.report_errors(
			"EnableTerrainCommand.run: Can not find terrain node",
			[
				"Terrain node %s could not be found" % name
			]
		)
		return ESCExecution.RC_ERROR
