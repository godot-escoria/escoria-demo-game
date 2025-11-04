## `teleport(object: String, target: String)`
##
## Instantly moves an object to a new position.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object|`String`|Global ID of the object to move|yes|[br]
## |target|`String`|Global ID of the object to use as the destination coordinates for `object`|yes|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name TeleportCommand


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
		raise_error(
			self,
			"Invalid first object.  Object to teleport with global id '%s' not found." % arguments[0]
		)
		return false

	if not (escoria.object_manager.get_object(arguments[0]).node as ESCItem):
		raise_error(
			self,
			"Invalid first object.  Object to teleport with global id '%s' must be of or derived from type ESCItem." % arguments[0]
		)
		return false

	if not escoria.object_manager.has(arguments[1]):
		raise_error(
			self,
			"Invalid second object. Destination location to teleport to with global id '%s' not found." % arguments[1]
		)
		return false
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
	(escoria.object_manager.get_object(command_params[0]).node as ESCItem) \
		.teleport(
			escoria.object_manager.get_object(command_params[1]).node
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
