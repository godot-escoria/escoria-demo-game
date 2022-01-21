# `walk object target [speed]`
#
# Moves the specified `ESCPlayer` or movable `ESCItem` to `target` w
# hile playing `object`'s walking animation. This command is non-blocking.
#
# **Parameters**
#
# - *object*: Global ID of the object to move
# - *target*: Global ID of the target object
# - *speed*: Walking speed to use (default: `object`'s default speed)
# 
# @ESC
extends ESCBaseCommand
class_name WalkCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING, TYPE_INT],
		[null, null, null]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"walk: invalid first object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false	
	if not escoria.object_manager.objects.has(arguments[1]):
		escoria.logger.report_errors(
			"walk: invalid second object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.action_manager.do(
		escoria.action_manager.ACTION.BACKGROUND_CLICK, 
		command_params
	)
	return ESCExecution.RC_OK
