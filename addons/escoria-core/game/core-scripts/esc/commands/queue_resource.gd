# `queue_resource path [front_of_queue]`
#
# Queues the load of a resource in a background thread. The `path` must be a 
# full path inside your game, for example "res://scenes/next_scene.tscn". The 
# "front_of_queue" parameter is optional (default value false), to put the 
# resource in the front of the queue. Queued resources are cleared when a 
# change scene happens (but after the scene is loaded, meaning you can queue 
# resources that belong to the next scene).
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


# Validate wether the given arguments match the command descriptor
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
