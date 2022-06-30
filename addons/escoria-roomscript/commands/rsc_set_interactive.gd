extends Node
class_name RSCSetInteractiveCommand

var set_interactive_command = SetInteractiveCommand.new()

# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_BOOL],
		[null, null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	return set_interactive_command.validate(RSCRoom.rewrite_command_params(arguments, 0))


func get_command_name() -> String:
	return "rsc_set_interactive"


# Run the command
func run(command_params: Array) -> int:
	return set_interactive_command.run(RSCRoom.rewrite_command_params(command_params, 0))
