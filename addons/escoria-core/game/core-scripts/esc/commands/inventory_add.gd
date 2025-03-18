## `inventory_add(item: String)`
##
## Adds an item to the inventory. If the player is picking up an object, you may
## want to use this command in conjunction with the `set_active` command so that
## the object 'disappears' from the scene as it's added to the inventory.[br]
##[br]
## **Parameters**[br]
##[br]
## - *item*: Global ID of the `ESCItem` to add to the inventory
##
## @ESC
extends ESCBaseCommand
class_name InventoryAddCommand


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
	escoria.inventory_manager.add_item(command_params[0])
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
