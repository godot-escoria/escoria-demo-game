# `set_angle object degrees [wait]`
#
# Turns a movable `ESCItem` or `ESCPlayer` to face a given angle.

# Angles 0 and 360 are the same and correspond to UP/NORTH,
# 90 is RIGHT/EAST, 180 is DOWN/SOUTH, 270 is LEFT/WEST etc.
#
# **Parameters**
#
# - *object*: Global ID of the object to turn
# - *degrees*: Number of degrees by which `object` is to be turned
# - *wait*: Number of seconds to wait for each animation occurring between the
#   current angle of `object` and the angle specified. A value of `0` will
#   complete the turn immediately (default: `0`)
#
# @ESC
extends ESCBaseCommand
class_name SetAngleCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_INT, TYPE_REAL],
		[null, null, 0.0]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.error(
			self,
			get_command_name() + ": invalid object. " + 
			"Object with global id %s not found" % arguments[0]
		)
		return false
	return true


# Run the command
func run(command_params: Array) -> int:
	# HACK Countering the fact that angle_to_point() function gives
	# angle against X axis not Y, we need to check direction using (angle-90°).
	# Since the ESC command already gives the right angle, we add 90.
	escoria.object_manager.get_object(command_params[0]).node\
			.set_angle(
				wrapi(int(command_params[1]) + 90, 0, 360),
				command_params[2]
			)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
