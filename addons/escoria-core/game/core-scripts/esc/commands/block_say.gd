## `block_say`[br]
## [br] 
## `say` commands called subsequent to using the `block_say` command will reuse the
## dialog box type of the previous `say` command if both dialog box types between the two `say`
## commands match.[br]
## [br]
## Different dialog box types can be used across multiple `say` commands, with the latest one
## used being preserved for reuse by the next `say` command should the dialog box type specified by
## both `say` commands match.[br]
## [br]
## This reuse will continue until a call to `end_block_say` is made.[br]
## [br]
## Using `block_say` more than once prior to calling `end_block_say` is idempotent and has the
## following behaviour:[br]
## [br]
## - If no `say` command has yet been encountered since the first use of `block_say`,
##   the result of using this command will be as described above.[br]
## - If a `say` command has been encountered since the previous use of `block_say`,
##   the dialog box used with that `say` command will continue to be reused for subsequent
##   `say` commands should the dialog box type requested match. Note that the dialog box used with
##   the next `say` command may be different than the one currently being reused.[br]
## [br]
## Example:[br]
## `block say`[br]
## `say player "Picture's looking good."`[br]
## `say player "And so am I."`[br]
## `end_block_say`[br]
## [br]
## This example will reuse the same dialog box type since they are the same between both `say` calls.[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name BlockSayCommand

## Constructor.
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
	escoria.dialog_player.enable_preserve_dialog_box()
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
