# `inventory_remove item`
#
# Removes an item from the inventory. You may wish to use this command in
# conjuction with the `set_active` command to show an item in the scene,
# simulating placing the item somewhere, for example.
#
# **Parameters**
#
# - *item*: Global ID of the `ESCItem` to remove from the inventory
#
# @ESC
extends ESCBaseCommand
class_name InventoryRemoveCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING],
		[null]
	)


# Run the command
func run(command_params: Array) -> int:
	escoria.inventory_manager.remove_item(command_params[0])
	return ESCExecution.RC_OK
