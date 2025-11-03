## `end_block_say()`
##
## `say` commands used subsequent to using the `end_block_say` command will no longer reuse the dialog box type used by the previous `say` command(s) encountered. Using `end_block_say` more than once is safe and idempotent. Example: `block say` `say player "Picture's looking good."` `say player "And so am I."` `end_block_say` This example will reuse the same dialog box type since they are the same between both `say` calls.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## None.[br]
## None.[br]
## None.[br]
## None.[br]
## None.[br]
## None.[br]
## None.[br]
## None.[br]
## None.[br]
## None.[br]
## None.[br]
## None.[br]
## None.[br]
## @ESC
extends ESCBaseCommand
class_name EndBlockSayCommand


## Constructor (bypasses the default constructor to avoid)[br]
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
	escoria.dialog_player.disable_preserve_dialog_box()
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
