## `say(player: String, text: String[, type: String])`
##
## Displays the specified string as dialog spoken by the player. This command
## blocks further event execution until the dialog has finished being 'said'
## (either as displayed text or as audible speech from a file).[br]
##[br]
## Global variables can be substituted into the text by wrapping the global
## name in braces, e.g. say player "I have {coin_count} coins remaining".[br]
##[br]
## **Parameters**[br]
##[br]
## - *player*: Global ID of the `ESCPlayer` or `ESCItem` object that is active.
##	You can specify `current_player` in order to refer to the currently active
##	player, e.g. in cases where multiple players are playable such as in games
##	like Maniac Mansion or Day of the Tentacle.[br]
## - *text*: Text to display.[br]
## - *key*: Translation key (default: nil)[br]
## - *type*: Dialog type to use. One of `floating` or `avatar`.
##   (default: the value set in the setting "Escoria/UI/Default Dialog Type")[br]
##[br]
## The text supports translation keys by prepending the key followed by
## a colon (`:`) to the text.[br]
##[br]
## For more details see: https://docs.escoria-framework.org/en/devel/getting_started/dialogs.html#translations[br]
##[br]
## Playing an audio file while the text is being
## displayed is also supported by this mechanism.
##[br]
## For more details see: https://docs.escoria-framework.org/en/devel/getting_started/dialogs.html#recorded_speech[br]
##[br]
## Example: `say(player, "Picture's looking good.", "ROOM1_PICTURE")`
##
## @ESC
extends ESCBaseCommand
class_name SayCommand


const CURRENT_PLAYER_KEYWORD = "CURRENT_PLAYER"


var globals_regex : RegEx		# Regex to match global variables in strings


# Constructor
func _init() -> void:
	globals_regex = RegEx.new()
	## Use look-ahead/behind to capture the term (i.e. global) in braces
	globals_regex.compile("(?<=\\{)(.*)(?=\\})")


## Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING],
		[
			null,
			null,
			"",
			""
		],
		[
			true,
			false,
			false,
			true
		]
	)


## Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if arguments[0].to_upper() != CURRENT_PLAYER_KEYWORD \
		and not escoria.object_manager.has(arguments[0]):
		raise_invalid_object_error(self, arguments[0])
		return false

	return true


## Run the command
func run(command_params: Array) -> int:
	var dict: Dictionary

	escoria.current_state = escoria.GAME_STATE.DIALOG

	if !escoria.dialog_player:
		raise_error(
			self,
			"No dialog player was registered and the 'say' command was encountered."
		)
		escoria.current_state = escoria.GAME_STATE.DEFAULT
		return ESCExecution.RC_ERROR

	if not escoria.main.current_scene.player:
		escoria.logger.warn(
			self,
			"[%s]: No player item in the current scene was registered and the say command was encountered."
					% get_command_name()
		)
		escoria.current_state = escoria.GAME_STATE.DEFAULT
		return ESCExecution.RC_CANCEL

	# Replace the names of any globals in "{ }" with their value
	command_params[1] = escoria.globals_manager.replace_globals(command_params[1])

	var speaking_character_global_id = escoria.main.current_scene.player.global_id \
		if command_params[0].to_upper() == CURRENT_PLAYER_KEYWORD \
		else command_params[0]

	escoria.dialog_player.say(
		speaking_character_global_id,
		command_params[3],
		command_params[1],
		command_params[2]
	)
	await escoria.dialog_player.say_finished
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
