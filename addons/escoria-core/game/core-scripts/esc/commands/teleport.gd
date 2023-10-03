# `teleport object target`
#
# Instantly moves an object to a new position.
#
# **Parameters**
#
# - *object*: Global ID of the object to move
# - *target*: Global ID of the object to use as the destination coordinates
#   for `object`
#
# @ESC
extends ESCBaseCommand
class_name TeleportCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING],
		[null, null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
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


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]).node as ESCItem) \
		.teleport(
			escoria.object_manager.get_object(command_params[1]).node
		)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
