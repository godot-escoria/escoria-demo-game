# `spawn identifier path [is_active] [position_target]`
#
# Programmatically adds a new item to the scene.
#
# **Parameters**
#
# - *identifier*: Global ID to use for the new object
# - *path*: Path to the scene file of the object
# - *is_active*: Whether the new object should be set to active (default: `true`)
# - *position_target*: Global ID of another object that will be used to
#   position the new object (when omitted, the new objet's position is not specified)
#
# @ESC
extends ESCBaseCommand
class_name SpawnCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING, TYPE_BOOL, TYPE_STRING],
		[null, null, true, null]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if arguments[0].empty() \
		or arguments[0] in escoria.object_manager.RESERVED_OBJECTS:
		escoria.logger.report_errors(
			"spawn: invalid global_id",
			[
				"global_id %s is invalid" % arguments[0]
			]
		)
		return false
	if not ResourceLoader.exists(arguments[1]):
		escoria.logger.report_errors(
			"spawn: invalid scene path",
			[
				"Scene with path %s not found" % arguments[1]
			]
		)
		return false
	if arguments[3] and not escoria.object_manager.objects.has(arguments[3]):
		escoria.logger.report_errors(
			"spawn: invalid object",
			[
				"Object with global id %s not found" % arguments[3]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	var res_scene = escoria.resource_cache.get_resource(command_params[1])
		
	# Load room scene
	var scene = res_scene.instance()
	if scene:
		escoria.main.get_node("/root").add_child(scene)
		if command_params[3]:
			var obj = escoria.object_manager.get_object(command_params[3])
			scene.set_position(obj.get_global_position())
		escoria.inputs_manager.hotspot_focused = ""
		
		escoria.object_manager.register_object(
			ESCObject.new(
				command_params[0],
				scene
			),
			true
		)
		
		escoria.object_manager.get_object(command_params[0]).active = \
			command_params[2]
		
	else:
		escoria.logger.report_errors(
			"spawn: Invalid scene", 
			[
				"Failed loading scene %s" % command_params[1]
			]
		)

	return ESCExecution.RC_OK
