## `save_game slot_id savegame_description`
##
## Saves the game in the [slot_id] slot, and sets the [savegame_description] in
## the savegame name/title.[br]
##[br]
## Example:[br]
## `save_game 1 "description of game saved`
##
## @ESC
extends ESCBaseCommand
class_name SaveGameCommand


# Constructor
func _init() -> void:
	pass


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_INT, TYPE_STRING],
		[1, "autosave"]
	)


## Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	return true


## Run the command
func run(command_params: Array) -> int:
	escoria.save_manager.save_game(command_params[0], command_params[1])
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
