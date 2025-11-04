## *** FOR INTERNAL USE ONLY *** `set_item_custom_data(item: String, custom_data: Dictionary)`
##
## Sets the "custom_data" of the item if it currently exists in the object manager.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |item|`String`|Global ID of the item whose `custom_data` should be updated.|yes|[br]
## |custom_data|`Dictionary`|Dictionary assigned to the item's `custom_data` property (an empty dictionary is used when `null`).|yes|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name SetItemCustomDataCommand


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
		[TYPE_STRING, TYPE_DICTIONARY],
		[null, null]
	)


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
	var global_id: String = command_params[0]
	if escoria.object_manager.has(global_id):
		var item = escoria.object_manager.get_object(global_id).node
		if item is ESCItem:
			item.set_custom_data(command_params[1])
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
