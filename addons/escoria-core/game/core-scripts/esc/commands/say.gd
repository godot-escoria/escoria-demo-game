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
# - *player*: Global ID of the `ESCPlayer` or `ESCItem` object that is active
# - *text*: Text to display
# - *type*: Dialog type to use. One of `floating` or `avatar`
#   (default: the value set in the setting "Escoria/UI/Default Dialog Type")
#
# The text supports translation keys by prepending the key followed by
# a colon (`:`) to the text.
#
# Example: `say player ROOM1_PICTURE:"Picture's looking good."`
#
# @ESC
extends ESCBaseCommand
class_name SayCommand


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

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.report_errors(
			"anim: invalid object",
			[
				"Object with global id %s not found." % arguments[0]
			]
		)
		return false
	if ProjectSettings.get_setting("escoria/ui/default_dialog_type") == "" \
			and arguments[2] == "":
		escoria.logger.report_errors(
			"say()",
			[
				"Project setting 'escoria/ui/default_dialog_type' is not set.",
				"Please set a default dialog type."
			]
		)
	return true


# Run the command
func run(command_params: Array) -> int:

	var dict: Dictionary

	escoria.current_state = escoria.GAME_STATE.DIALOG

	if !escoria.dialog_player:
		escoria.logger.report_errors(
			"No dialog player registered",
			[
				"No dialog player was registered and the say command was" +
						"encountered."
			]
		)
		return ESCExecution.RC_ERROR

	# Replace the names of any globals in "{ }" with their value
	command_params[1] = escoria.logger.replace_globals(command_params[1])

	escoria.dialog_player.say(
		command_params[0],
		command_params[2],
		command_params[1]
	)
	yield(escoria.dialog_player, "say_finished")
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	return ESCExecution.RC_OK
