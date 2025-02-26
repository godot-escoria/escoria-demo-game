# `set_direction object direction_id [wait]`
#
# Turns a movable `ESCItem` or `ESCPlayer` to face a given target direction id
# (between 0 and 3 for a 4-directional character, or between 0 and 7 for an
# 8-directional character).
#
# 4-directional :
# 0 : UP / NORTH
# 1 : RIGHT / EAST
# 2 : DOWN / SOUTH
# 3 : LEFT / WEST
#
# 8-directional :
# 0 : UP / NORTH
# 1 : UP-RIGHT / NORTH-EAST
# 2 : RIGHT / EAST
# 3 : DOWN-RIGHT / SOUTH-EAST
# 4 : DOWN / SOUTH
# 5 : DOWN-LEFT / SOUTH-WEST
# 6 : LEFT / WEST
# 7 : TOP-LEFT / NORTH-WEST
#
# **Parameters**
#
# - *object*: Global ID of the object to turn
# - *target_direction_id*: id of the direction as defined in the player animations
# - *wait*: Number of seconds to wait while playing each animation occurring
#   between the current direction of `object` and the target direction. A value of
#   `0` will complete the turn immediately (default: `0`)
#
# @ESC
extends ESCBaseCommand
class_name SetDirectionCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING,  [TYPE_INT],  [TYPE_FLOAT, TYPE_INT]],
		[null, null, 0.0]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.error(
			self,
			"[%s]: invalid object. Object with global id %s not found."
					% [get_command_name(), arguments[0]]
		)
		return false
	elif not escoria.object_manager.get_object(arguments[0]).node.is_movable:
		escoria.logger.error(
			self,
			"[%s]: invalid object. Object with global id %s is not movable."
					% [get_command_name(), arguments[0]]
		)
		return false
	elif arguments[1] < 0 or arguments[1] > escoria.object_manager.get_object(arguments[0]).node \
			.get_directions_quantity() - 1:
		escoria.logger.error(
			self,
			"[%s]: invalid direction id for object %s. Valid values are integer values between 0 and %s."
					% [get_command_name(), arguments[0], escoria.object_manager.get_object(arguments[0]) \
						.node.get_directions_quantity() - 1]
		)
		return false

	return true


# Run the command
func run(command_params: Array) -> int:
	escoria.object_manager.get_object(command_params[0]).node \
			.set_direction(command_params[1], command_params[2])
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
