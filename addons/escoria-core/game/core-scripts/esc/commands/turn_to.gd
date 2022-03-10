# `turn_to object object_to_face [wait]`
#
# Turns `object` to face another object.
#
# Unlike movement commands, `turn_to` will not automatically reference an
# `ESCLocation` that is a child of an `ESCItem.`
# To turn towards an `ESCLocation` that is a child of an `ESCItem`, give the
# `ESCLocation` a `Global ID` and use this value as the `object_to_face`
# parameter.
#
# **Parameters**
#
# - *object*: Global ID of the object to be turned
# - *object_to_face*: Global ID of the object to turn towards
# - *wait*: Length of time to wait in seconds for each intermediate angle.
#   If set to 0, the turnaround is immediate (default: `0`)
#
# @ESC
extends ESCBaseCommand
class_name TurnToCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_REAL],
		[null, null, 0.0]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"turn_to: invalid object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false
	if not escoria.object_manager.objects.has(arguments[1]):
		escoria.logger.report_errors(
			"turn_to: invalid target object",
			[
				"Object with global id %s not found" % arguments[1]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]).node as ESCItem)\
		.turn_to(
			escoria.object_manager.get_object(command_params[1]).node,
			command_params[2]
		)
	return ESCExecution.RC_OK
