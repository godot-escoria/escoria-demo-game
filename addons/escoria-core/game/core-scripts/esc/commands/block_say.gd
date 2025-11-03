## `block_say()`
##
## `say` commands called subsequent to using the `block_say` command will reuse the dialog box type of the previous `say` command if both dialog box types between the two `say` commands match. Different dialog box types can be used across multiple `say` commands, with the latest one used being preserved for reuse by the next `say` command should the dialog box type specified by both `say` commands match. This reuse will continue until a call to `end_block_say` is made. Using `block_say` more than once prior to calling `end_block_say` is idempotent and has the following behaviour: - If no `say` command has yet been encountered since the first use of `block_say`, the result of using this command will be as described above. - If a `say` command has been encountered since the previous use of `block_say`, the dialog box used with that `say` command will continue to be reused for subsequent `say` commands should the dialog box type requested match. Note that the dialog box used with the next `say` command may be different than the one currently being reused. Example: `block say` `say player "Picture's looking good."` `say player "And so am I."` `end_block_say` This example will reuse the same dialog box type since they are the same between both `say` calls.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## @ESC
extends ESCBaseCommand
class_name BlockSayCommand


## Constructor[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _init() -> void:
	pass

## The descriptor of the arguments of this command.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the descriptor of the arguments of this command. The argument descriptor for this command. (`ESCCommandArgumentDescriptor`)
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(0)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |arguments|`Array`|The arguments to validate.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns True if the arguments are valid, false otherwise. (`bool`)
func validate(arguments: Array):
	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_params|`Array`|The parameters for the command.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the execution result code. (`int`)
func run(command_params: Array) -> int:
	escoria.dialog_player.enable_preserve_dialog_box()
	return ESCExecution.RC_OK


## Function called when the command is interrupted.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
