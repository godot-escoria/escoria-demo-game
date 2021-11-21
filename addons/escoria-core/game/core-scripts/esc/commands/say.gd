# `say player text [type]`
#
# Runs the specified string as a dialog said by the player. Blocks execution 
# until the dialog finishes playing. 
#
# The text supports translation keys by prepending the key and separating
# it with a `:` from the text.
# 
# Example: `say player ROOM1_PICTURE:"Picture's looking good."`
#
# Optional parameters:
# 
# * "type" determines the type of dialog UI to use. Default value is "default"
#
# @ESC
extends ESCBaseCommand
class_name SayCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING, TYPE_STRING],
		[
			null, 
			null, 
			""
		]
	)
	
	
# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
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
	return .validate(arguments)
	

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
	
	escoria.dialog_player.say(
		command_params[0], 
		command_params[2], 
		command_params[1]
	)
	yield(escoria.dialog_player, "say_finished")
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	return ESCExecution.RC_OK
