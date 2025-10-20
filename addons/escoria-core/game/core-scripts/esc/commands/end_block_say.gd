## `end_block_say()`
##
## `say` commands used subsequent to using the `end_block_say` command will no longer
## reuse the dialog box type used by the previous `say` command(s) encountered.[br]
##[br]
## Using `end_block_say` more than once is safe and idempotent.[br]
##[br]
## Example:[br]
## `block say`[br]
## `say player "Picture's looking good."`[br]
## `say player "And so am I."`[br]
## `end_block_say`[br]
##[br]
## This example will reuse the same dialog box type since they are the same between both `say` calls.
##
## @ESC
extends ESCBaseCommand
class_name EndBlockSayCommand


## Constructor (bypasses the default constructor to avoid)
func _init() -> void:
	pass


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(0)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## - arguments: The arguments to validate.[br]
## [br]
## *Returns* True if the arguments are valid, false otherwise.
func validate(arguments: Array):
	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	escoria.dialog_player.disable_preserve_dialog_box()
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
