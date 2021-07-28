# `say object text [type] [avatar]`
#
# Runs the specified string as a dialog said by the object. Blocks execution 
# until the dialog finishes playing. Optional parameters:
# 
# * "type" determines the type of dialog UI to use. Default value is "default"
# * "avatar" determines the avatar to use for the dialog. Default value is 
#   "default"
#
# @ESC
extends ESCBaseCommand
class_name SayCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING],
		[
			null, 
			null, 
			ProjectSettings.get_setting("escoria/ui/default_dialog_scene")\
					.get_file().get_basename(), 
			"default"
		]
	)


# Run the command
func run(command_params: Array) -> int:
	
	var dict: Dictionary
	var dialog_scene_name = ProjectSettings.get_setting(
		"escoria/ui/default_dialog_scene"
	)
	
	if dialog_scene_name.empty():
		escoria.logger.report_errors(
			"say()", 
			[
				"Project setting 'escoria/ui/default_dialog_scene' is not set.", 
				"Please set a default dialog scene."
			]
		)
		return ESCExecution.RC_ERROR
		
	var file = dialog_scene_name.get_file()
	var extension = dialog_scene_name.get_extension()
	dialog_scene_name = file.rstrip("." + extension)
	
	# Manage specific dialog scene
	if command_params.size() > 2:
		dialog_scene_name = command_params[2]
	
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
		dialog_scene_name, 
		command_params[1]
	)
	yield(escoria.dialog_player, "dialog_line_finished")
	return ESCExecution.RC_OK
