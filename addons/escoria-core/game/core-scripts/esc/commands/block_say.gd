# `block_say`
#
# `say` commands used subsequent to using the `block_say` command will reuse the
# dialog box type used by the next `say` command encountered. This reuse will
# continue until a call to `end_block_say` is made.
#
# Using `block_say` more than once prior to calling `end_block_say` has the following
# behaviour:
#
# - If no `say` command has yet been encountered since the first use of `block_say`,
#   the result of using this command will be as described above.
# - If a `say` command has been encountered since the first use of `block_say`,
#   the dialog box used with that `say` command will continue to be used for subsequent
#   `say` commands. Note that the dialog box used with the next `say` command may be
#   different than the one currently being reused.
#
# Example:
# `block say`
# `say player "Picture's looking good."`
# `say player "And so am I."`
# `end_block_say`
#
# @ESC
extends ESCBaseCommand
class_name BlockSayCommand


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
	escoria.dialog_player.enable_preserve_dialog_box()
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
