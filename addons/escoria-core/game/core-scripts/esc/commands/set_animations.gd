# `set_animations object animations`
#
# Set the animation resource for the given ESCPlayer or movable ESCItem.
#
# **Parameters**
#
# - *object*: Global ID of the object to change
# - *animations*: The path to the animations resource to use
#
# @ESC
extends ESCBaseCommand
class_name SetAnimationsCommand


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
			"set_animations: invalid object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	if not ResourceLoader.exists(arguments[1]):
		escoria.logger.report_errors(
			"set_animations: invalid animations",
			[
				"The animation resource %s was not found" % arguments[1]
			]
		)
		return false
	return .validate(arguments)
	

# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]).node as ESCPlayer)\
			.animations = load(command_params[1])
	return ESCExecution.RC_OK
	
