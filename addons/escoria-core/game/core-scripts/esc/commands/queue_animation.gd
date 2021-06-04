# `queue_animation object animation`
#
# Similar to queue_resource, queues the resources necessary to have an 
# animation loaded on an item. The resource paths are taken from the item 
# placeholders.
#
# @STUB
# @ESC
extends ESCBaseCommand
class_name QueueAnimationCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING],
		[null, null]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"queue_animation: invalid first object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false	
	# TODO: Check if animation is valid
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.logger.report_errors(
		"queue_animation: command not implemented",
		[]
	)
	return ESCExecution.RC_ERROR
