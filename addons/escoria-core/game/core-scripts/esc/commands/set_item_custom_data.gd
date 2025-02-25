## *** FOR INTERNAL USE ONLY *** `set_item_custom_data item custom_data`
##
## Sets the "custom_data" of the item if it currently exists in the object manager.[br]
##[br]
## **Parameters**[br]
##[br]
## - *item* Global ID of the item[br]
## - *custom_data* Dictionary with custom data. If null empty dictionary will be assigned.
##
## @ESC
extends ESCBaseCommand
class_name SetItemCustomDataCommand


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_DICTIONARY],
		[null, null]
	)


## Run the command
func run(command_params: Array) -> int:
	var global_id: String = command_params[0]
	if escoria.object_manager.has(global_id):
		var item = escoria.object_manager.get_object(global_id).node
		if item is ESCItem:
			item.set_custom_data(command_params[1])
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
