## `save_game slot_id savegame_description`[br]
## [br]
## Saves the game in the [slot_id] slot, and sets the [savegame_description] in
## the savegame name/title.[br]
## [br]
## #### Parameters[br]
## [br]
## - *slot_id*: The slot to save the game in. This is an integer value
##   starting from 1. If the slot is already occupied, it will be overwritten.[br]
## - *savegame_description*: The description of the savegame. This is a string
##   value that will be used to name the savegame file.[br]
## [br]
## Example:[br]
## `save_game 1 "description of game saved"`[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name SaveGameCommand


## Constructor
func _init() -> void:
	pass


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_INT, TYPE_STRING],
		[1, "autosave"]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## - arguments: The arguments to validate.[br]
## [br]
## *Returns* True if the arguments are valid, false otherwise.
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	return true



## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	escoria.save_manager.save_game(command_params[0], command_params[1])
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
