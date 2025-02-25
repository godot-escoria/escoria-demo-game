## `inventory_remove item`
##
## Removes an item from the inventory. You may wish to use this command in
## conjuction with the `set_active` command to show an item in the scene,
## simulating placing the item somewhere, for example.[br]
##[br]
## **Parameters**[br]
##[br]
## - *item*: Global ID of the `ESCItem` to remove from the inventory
##
## @ESC
extends ESCBaseCommand
class_name InventoryRemoveCommand


const ILLEGAL_STRINGS = ["/"]


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING],
		[null]
	)


## Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	for s in ILLEGAL_STRINGS:
		if s in arguments[0]:
			raise_error(self, "Invalid item name. Item name '%s' cannot contain the string '%s'."
			% [arguments[0], s])

			return false

	return true


## Run the command
func run(command_params: Array) -> int:
	escoria.inventory_manager.remove_item(command_params[0])
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
