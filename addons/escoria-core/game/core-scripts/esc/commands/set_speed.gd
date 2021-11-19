# `set_speed object speed`
#
# Sets the speed of a movable ESCItem or ESCPlayer.
#
# **Parameters**
#
# - *object*: Global ID of the movable ESCItem or ESCPlayer
# - *speed*: Speed value for the object
#
# @ESC
extends ESCBaseCommand
class_name SetSpeedCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_INT],
		[null, null]
	)

# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"set_speed: invalid object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	return .validate(arguments)

# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.objects[command_params[0]].node as ESCItem).\
			set_speed(command_params[1])
	return ESCExecution.RC_OK
