# `say player text [type]`
#
# Displays the specified string as dialog spoken by the player. This command
# blocks further event execution until the dialog has finished being 'said'
# (either as displayed text or as audible speech from a file).
#
# Global variables can be substituted into the text by wrapping the global
# name in braces.
# e.g. say player "I have {coin_count} coins remaining".
#
# **Parameters**
#
# - *player*: Global ID of the `ESCPlayer` or `ESCItem` object that is active.
#	You can specify `current_player` in order to refer to the currently active
#	player, e.g. in cases where multiple players are playable such as in games
#	like Maniac Mansion or Day of the Tentacle.
# - *text*: Text to display.
# - *type*: Dialog type to use. One of `floating` or `avatar`.
#   (default: the value set in the setting "Escoria/UI/Default Dialog Type")
#
# The text supports translation keys by prepending the key followed by
# a colon (`:`) to the text.
# For more details see: https://docs.escoria-framework.org/en/devel/getting_started/dialogs.html#translations
#
# Playing an audio file while the text is being
# displayed is also supported by this mechanism.
# For more details see: https://docs.escoria-framework.org/en/devel/getting_started/dialogs.html#recorded_speech
#
# Example: `say player ROOM1_PICTURE:"Picture's looking good."`
#
# @ESC
extends ESCBaseCommand
class_name SayCommand


const CURRENT_PLAYER_KEYWORD = "CURRENT_PLAYER"


var globals_regex : RegEx		# Regex to match global variables in strings


# Constructor
func _init() -> void:
	globals_regex = RegEx.new()
	# Use look-ahead/behind to capture the term (i.e. global) in braces
	globals_regex.compile("(?<=\\{)(.*)(?=\\})")


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_STRING],
		[
			null,
			null,
			""
		],
		[
			true,
			false,
			true
		]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if arguments[0].to_upper() != CURRENT_PLAYER_KEYWORD \
		and not escoria.object_manager.has(arguments[0]):
		escoria.logger.error(
			self,
			"[%s]: Invalid object: Object with global id %s not found."
					% [get_command_name(), arguments[0]]
		)
		return false

	if ESCProjectSettingsManager.get_setting(ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE) == "" \
			and arguments[2] == "":
		escoria.logger.error(
			self,
			"[%s]: Project setting '%s' is not set. Please set a default dialog type."
					% [get_command_name(), ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE]
		)
	return true


# Run the command
func run(command_params: Array) -> int:
	var dict: Dictionary

	escoria.current_state = escoria.GAME_STATE.DIALOG

	if !escoria.dialog_player:
		escoria.logger.error(
			self,
			"[%s]: No dialog player was registered and the say command was encountered."
					% get_command_name()
		)
		return ESCExecution.RC_ERROR

	# Replace the names of any globals in "{ }" with their value
	command_params[1] = escoria.globals_manager.replace_globals(command_params[1])

	var player_character_global_id = escoria.main.current_scene.player.global_id \
		if command_params[0].to_upper() == CURRENT_PLAYER_KEYWORD \
		else command_params[0]

	escoria.dialog_player.say(
		player_character_global_id,
		command_params[2],
		command_params[1]
	)
	yield(escoria.dialog_player, "say_finished")
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.warn(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
