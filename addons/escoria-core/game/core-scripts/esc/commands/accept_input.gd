# `accept_input [type]`
#
# Set what type of input the game accepts from now on.
# This allows cut scenes where the dialog can be skipped if set to SKIP or
# even completely locked down cut scenes.
#
# **Parameters**
#
# - *type*: Type of input to accept (ALL)
#   `ALL`: Accept all types of input
#   `SKIP`: Accept skipping dialogs but nothing else
#   `NONE`: Denies all input (including opening menus)
#
# **Warning**: `SKIP` and `NONE` also disables autosaves.
#
# **Note**: If `SKIP` is specified, it will be reset to `ALL` when the event has
# finished. `NONE` persists after the event.
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
