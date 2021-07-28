# Escoria dialog player
tool
extends ResourcePreloader
class_name ESCDialogsPlayer


# Emitted when an answer as chosem
# 
# ##### Parameters
#
# - option: The dialog option that was chosen
signal option_chosen(option)

# Emitted when a dialog line was finished
signal dialog_line_finished


# Wether the player is currently speaking
var is_speaking = false

# Reference to the dialog UI
var _dialog_ui = null

# Reference to the dialog chooser UI
var _dialog_chooser_ui = null


# Register the dialog player and load the dialog resources
func _ready():
	if !Engine.is_editor_hint():
		escoria.dialog_player = self
	preload_resources(ProjectSettings.get_setting("escoria/ui/dialogs_folder"))


# Preload the dialog UI resources
#
# #### Parameters
#
# - path: Path where the actual dialog UI resources are located
func preload_resources(path: String) -> void:
	var dialog_folder := Directory.new()
	if !path.empty() and dialog_folder.open(path) == OK:
		dialog_folder.list_dir_begin()
		var file_name = dialog_folder.get_next()
		while file_name != "":
			if !dialog_folder.current_is_dir() \
					and file_name.get_extension() == "tscn":
				var extension = "." + file_name.get_extension()
				var basename = file_name.replace(extension, "")
				
				if !has_resource(basename):
					var file_path = "%s/%s" % [
						dialog_folder.get_current_dir(),
						file_name
					]
					var dialog_scene = load(file_path)
					
					if dialog_scene != null:
						add_resource(basename, dialog_scene)
			file_name = dialog_folder.get_next()
	else:
		escoria.logger.report_errors(
			"dialog_player.gd:preload_resources()", 
			[
				"An error occurred when trying to access the path: %s." % path
			]
		)


# A short one line dialog
#
# #### Parameters
#
# - character: Character that is talking
# - params: A dictionary of parameters. Currently only "line" is supported and
#   holds the line the character should say
func say(character: String, params: Dictionary) -> void:
	is_speaking = true
	_dialog_ui = get_resource(params.ui).instance()
	get_parent().add_child(_dialog_ui)
	_dialog_ui.say(character, params)
	yield(_dialog_ui, "dialog_line_finished")
	emit_signal("dialog_line_finished")
	

# Called when a dialog line is skipped
func finish_fast() -> void:
	if escoria.inputs_manager.input_mode != escoria.inputs_manager.INPUT_NONE:
		_dialog_ui.finish_fast()


# Display a list of choices
func start_dialog_choices(dialog: ESCDialog):
	if dialog.options.empty():
		escoria.logger.report_errors(
			"dialog_player.gd:start_dialog_choices()", 
			["Received answers array was empty."]
		)
	_dialog_chooser_ui = get_resource("text_dialog_choice").instance()
	get_parent().add_child(_dialog_chooser_ui)
	
	_dialog_chooser_ui.set_answers(dialog.options)


# Called when an option was chosen
func play_dialog_option_chosen(option: ESCDialogOption):
	emit_signal("option_chosen", option)
	_dialog_chooser_ui.hide()

