# `set_active_if_exists object active`
#
# *** FOR INTERNAL USE ONLY ***
#
# Changes the "active" state of the object in the current room if it currently
# exists in the object manager. If it doesn't, then, unlike set_active, we don't
# fail and we just carry on.
#
# Inactive objects are invisible in the room.
#
# **Parameters**
#
# - *object* Global ID of the object
# - *active* Whether `object` should be active. `active` can be `true` or `false`.
#
# @ESC
extends ESCBaseCommand
class_name SetActiveIfExistsCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_BOOL],
		[null, null]
	)


# Run the command
func run(command_params: Array) -> int:
	if escoria.object_manager.has(command_params[0]):
		escoria.object_manager.get_object(command_params[0]).active = \
				command_params[1]
	return ESCExecution.RC_OK
