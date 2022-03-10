# `queue_resource path [front_of_queue]`
#
# Queues the loading of the given resource into the resource cache.
#
# **Parameters**
#
# - *path*: Path of the resource to cache
# - *front_of_queue*: Whether to put the resource at the front of the
#   queue in order to load it as soon as possible (default: `false`)
#
# @ESC
extends ESCBaseCommand
class_name QueueResourceCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[],
		[null, false]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array) -> bool:
	if not ResourceLoader.exists(arguments[0]):
		escoria.logger.report_errors(
			"queue_resource: Invalid resource",
			["Resource %s was not found" % arguments[0]]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.resource_cache.queue_resource(
		command_params[0],
		command_params[1]
	)
	return ESCExecution.RC_OK
