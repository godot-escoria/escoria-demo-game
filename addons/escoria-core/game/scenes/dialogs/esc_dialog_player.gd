# Escoria dialog player
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
var _dialog_chooser_ui: ESCDialogOptionsChooser = null


# Register the dialog player and load the dialog resources
func _ready():
	if !Engine.is_editor_hint():
		escoria.dialog_player = self
		_dialog_chooser_ui = ResourceLoader.load(
			ProjectSettings.get_setting("escoria/ui/dialogs_chooser")
		).instance()
		assert(_dialog_chooser_ui is ESCDialogOptionsChooser)
		_dialog_chooser_ui.connect(
			"option_chosen", 
			self, 
			"play_dialog_option_chosen"
		)
		get_parent().call_deferred("add_child", _dialog_chooser_ui)


# Trigger the finish fast function on the dialog ui
#
# #### Parameters
#
# - event: The input event
func _input(event):
	if event is InputEventMouseButton and \
			event.pressed:
		finish_fast()
		

func _get_voice_file(key: String, start: String = "") -> String:
	if start == "":
		start = ProjectSettings.get("escoria/sound/speech_folder")
	var _dir = Directory.new()
	if _dir.open(start) == OK:
		_dir.list_dir_begin(true, true)
		var file_name = _dir.get_next()
		while file_name != "":
			if _dir.current_is_dir():
				var _voice_file = _get_voice_file(
					key, 
					start.plus_file(file_name)
				)
				if _voice_file != "":
					return _voice_file
			else:
				if file_name == "%s.%s" % [
					key, 
					ProjectSettings.get("escoria/sound/speech_extension")
				]:
					return start.plus_file(file_name)
			file_name = _dir.get_next()
	return ""


# A short one line dialog
#
# #### Parameters
#
# - character: Character that is talking
# - ui: UI to use for the dialog
# - line: Line to say
func say(character: String, ui: String, line: String) -> void:
	is_speaking = true
	_dialog_ui = get_resource(ui).instance()
	get_parent().add_child(_dialog_ui)
	var _key_line = line.split(":")
	if _key_line.size() == 2:
		var _speech_resource = _get_voice_file(_key_line[0])
		if _speech_resource != "":
			(
				escoria.object_manager.get_object("_speech").node\
				 as ESCSpeechPlayer
			).set_state(_speech_resource)
	_dialog_ui.say(character, _key_line[1])
	yield(_dialog_ui, "dialog_line_finished")
	is_speaking = false
	emit_signal("dialog_line_finished")
	

# Called when a dialog line is skipped
func finish_fast() -> void:
	if is_speaking and\
			escoria.inputs_manager.input_mode != escoria.inputs_manager.INPUT_NONE:
		_dialog_ui.finish_fast()


# Display a list of choices
#
# #### Parameters
#
# - dialog: The dialog to start
func start_dialog_choices(dialog: ESCDialog):
	if dialog.options.empty():
		escoria.logger.report_errors(
			"dialog_player.gd:start_dialog_choices()", 
			["Received answers array was empty."]
		)
	_dialog_chooser_ui.set_dialog(dialog)
	_dialog_chooser_ui.show_chooser()


# Called when an option was chosen and emits the option_chosen signal
#
# #### Parameters
#
# - option: Option, that was chosen.
func play_dialog_option_chosen(option: ESCDialogOption):
	emit_signal("option_chosen", option)
	_dialog_chooser_ui.hide_chooser()

