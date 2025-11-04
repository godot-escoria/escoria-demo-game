## `set_animations(object: String, animations: String)`
##
## Sets the animation resource for the given `ESCPlayer` or movable `ESCItem`.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object|`String`|Global ID of the object whose animation resource is to be updated|yes|[br]
## |animations|`String`|The path of the animation resource to use|yes|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name SetAnimationsCommand


## The descriptor of the arguments of this command.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the descriptor of the arguments of this command. The argument descriptor for this command. (`ESCCommandArgumentDescriptor`)
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING],
		[null, null]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |arguments|`Array`|The arguments to validate.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns True if the arguments are valid, false otherwise. (`bool`)
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		raise_invalid_object_error(self, arguments[0])
		return false
	if not ResourceLoader.exists(arguments[1]):
		raise_error(
			self,
			"Invalid animation resource. The animation resource '%s' was not found." % arguments[1]
		)
		return false

	(escoria.object_manager.get_object(arguments[0]).node as ESCPlayer).validate_animations(load(arguments[1]))

	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_params|`Array`|The parameters for the command.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the execution result code. (`int`)
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]).node as ESCPlayer)\
			.animations = load(command_params[1])
	if not escoria.globals_manager.has(
		escoria.room_manager.GLOBAL_ANIMATION_RESOURCES
	):
		escoria.globals_manager.set_global(
			escoria.room_manager.GLOBAL_ANIMATION_RESOURCES,
			{},
			true
		)
	var animations: Dictionary = escoria.globals_manager.get_global(
		escoria.room_manager.GLOBAL_ANIMATION_RESOURCES
	)
	if animations.is_empty():
		animations = {}
		animations[command_params[0]] = command_params[1]
	escoria.globals_manager.set_global(
		escoria.room_manager.GLOBAL_ANIMATION_RESOURCES,
		animations,
		true
	)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func interrupt():
	# Do nothing
	pass
