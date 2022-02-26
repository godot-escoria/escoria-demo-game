# `walk_block object target [speed]`
#
# Moves the specified `ESCPlayer` or movable `ESCItem` to `target`
# while playing `object`'s walking animation. This command is blocking.
#
# **Parameters**
#
# - *object*: Global ID of the object to move
# - *target*: Global ID of the target object
# - *speed*: The speed the `object` will walk in pixels per second (will 
#   default to the speed configured on the `object`)
#
# @ESC
extends ESCBaseCommand
class_name WalkBlockCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_INT],
		[null, null, null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"walk_block: invalid first object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	if not escoria.object_manager.objects.has(arguments[1]):
		escoria.logger.report_errors(
			"walk_block: invalid second object",
			[
				"Object with global id %s not found" % arguments[1]
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
	yield(
		(escoria.object_manager.objects[command_params[0]].node as ESCItem),
		"arrived"
	)
	return ESCExecution.RC_OK
