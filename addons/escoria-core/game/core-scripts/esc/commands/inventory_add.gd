# `inventory_add item`
#
# Adds an item to the inventory. If the player is picking up an object, you may
# want to use this command in conjunction with the `set_active` command so that
# the object 'disappears' from the scene as it's added to the inventory.
#
# **Parameters**
#
# - *item*: Global ID of the `ESCItem` to add to the inventory
#
# @ESC
extends ESCBaseCommand
class_name InventoryAddCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING],
		[null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if arguments[0].begins_with("i/"):
		escoria.logger.error(
			self,
			"[%s]: invalid item name. Item name %s cannot start with 'i/'." 
					% [get_command_name(), arguments[0]]
		)
		return false
	return true


# Run the command
func run(command_params: Array) -> int:
	escoria.inventory_manager.add_item(command_params[0])
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
