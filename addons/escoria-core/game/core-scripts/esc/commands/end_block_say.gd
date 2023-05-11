# `end_block_say`
#
# `say` commands used subsequent to using the `end_block_say` command will no longer
# reuse the dialog box type used by the previous `say` command(s) encountered. 
#
# Using `end_block_say` more than once is safe and idempotent.
#
# Example:
# `block say`
# `say player "Picture's looking good."`
# `say player "And so am I."`
# `end_block_say`
#
# @ESC
extends ESCBaseCommand
class_name EndBlockSayCommand


# Constructor
func _init() -> void:
	pass


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(0)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	return true


# Run the command
func run(command_params: Array) -> int:
	escoria.dialog_player.disable_preserve_dialog_box()
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
