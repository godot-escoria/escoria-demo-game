## `spawn(identifier: String, path: String[, is_active: Boolean[, position_target: String]])`
##
## Programmatically adds a new item to the scene.[br]
##[br]
## **Parameters**[br]
##[br]
## - *identifier*: Global ID to use for the new object[br]
## - *path*: Path to the scene file of the object[br]
## - *is_active*: Whether the new object should be set to active (default: `true`)[br]
## - *position_target*: Global ID of another object that will be used to
##   position the new object (when omitted, the new object's position is not specified)
##
## @ESC
extends ESCBaseCommand
class_name SpawnCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_BOOL, TYPE_STRING],
		[null, null, true, null]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## - arguments: The arguments to validate.[br]
## [br]
## *Returns* True if the arguments are valid, false otherwise.
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if arguments[0].is_empty() \
		or arguments[0] in escoria.object_manager.RESERVED_OBJECTS:
		raise_error(
			self,
			"global_id (%s) is invalid. The global_id was either empty or is reserved." % arguments[0]
		)
		return false
	if not ResourceLoader.exists(arguments[1]):
		raise_error(
			self,
			"Invalid scene path: '%s' not found." % arguments[1]
		)
		return false
	if arguments[3] and not escoria.object_manager.has(arguments[3]):
		raise_invalid_object_error(self, arguments[3])
		return false
	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	var res_scene = escoria.resource_cache.get_resource(command_params[1])

	# Load room scene
	var scene = res_scene.instantiate()
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
			null,
			true
		)

		escoria.object_manager.get_object(command_params[0]).active = \
			command_params[2]

	else:
		raise_error(
			self,
			"Invalid scene. Failed to load scene '%s'." % command_params[1]
		)

	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
