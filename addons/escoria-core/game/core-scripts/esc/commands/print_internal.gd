## INTERNAL USE ONLY[br]
## [br]
## `print string`[br]
## [br]
## Prints a message to the Godot debug window.[br]
## Use this for debugging game state.[br]
## [br]
## #### Parameters[br]
## [br]
## - *string*: The string to log[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name PrintCommand


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING],
		[""]
	)


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	# Replace the names of any globals in "{ }" with their value
	print(escoria.globals_manager.replace_globals(command_params[0]))
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass
