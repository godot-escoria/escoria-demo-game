# `accept_input [ALL|NONE|SKIP]`
#
# What type of input does the game accept. ALL is the default, SKIP allows 
# skipping of dialog but nothing else, NONE denies all input. Including opening 
# the menu etc. SKIP and NONE also disable autosaves.
#
# *Note* that SKIP gets reset to ALL when the event is done, but NONE persists. 
# This allows you to create cut scenes with SKIP where the dialog can be 
# skipped, but also initiate locked#### down cutscenes with accept_input 
# NONE in :setup and accept_input ALL later in :ready.
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
