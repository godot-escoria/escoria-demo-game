# `accept_input [type]`
#
# Sets how much input the game is to accept, allowing for cut scenes
# in which dialog can be skipped (if [type] is set to SKIP).
# Also allows for cut scenes that can be completely locked down.
#
# **Parameters**
#
# - *type*: Type of inputs to accept (ALL)
#   `ALL`: Accept all types of input
#   `SKIP`: Accept skipping dialogs but nothing else
#   `NONE`: Deny all inputs (including opening menus)
#
# **Warning**: `SKIP` and `NONE` also disable autosaves.
#
# **Warning**: The type of input accepted will persist even after the current
# event has ended.
#
# @ESC
extends ESCBaseCommand
class_name AcceptInputCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_STRING],
		["ALL"]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not arguments[0] in ["ALL", "NONE", "SKIP"]:
		escoria.logger.report_errors(
			"accept_input: invalid parameter",
			[
				"%s is not a valid parameter value (ALL, NONE, SKIP)" %\
						arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	var mode = escoria.inputs_manager.INPUT_ALL
	match command_params[0]:
		"NONE":
			mode = escoria.inputs_manager.INPUT_NONE
		"SKIP":
			mode = escoria.inputs_manager.INPUT_SKIP
	
	escoria.inputs_manager.input_mode = mode
	return ESCExecution.RC_OK
