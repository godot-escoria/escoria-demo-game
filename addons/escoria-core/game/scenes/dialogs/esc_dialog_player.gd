# Escoria dialog player
extends Node
class_name ESCDialogPlayer


# A regular expression that separates the translation key from the text
const KEYTEXT_REGEX = "^((?<key>[^:]+):)?\"(?<text>.+)\""


# Emitted when an answer as chosem
#
# ##### Parameters
#
# - option: The dialog option that was chosen
signal option_chosen(option)

# Emitted when a say command finished
signal say_finished


# Whether the player is currently speaking
var is_speaking: bool = false


# Reference to the currently playing dialog manager
var _dialog_manager: ESCDialogManager = null


# Regular expression object for the separation of key and text
var _keytext_regex: RegEx = RegEx.new()


# Constructor
func _init() -> void:
	_keytext_regex.compile(KEYTEXT_REGEX)


# Register the dialog player and load the dialog resources
func _ready():
	if !Engine.is_editor_hint():
		escoria.dialog_player = self


# Trigger the speedup function in the dialog manager
#
# #### Parameters
#
# - event: The input event
func _input(event):
	if event is InputEventMouseButton and event.pressed and is_speaking:
		speedup()
		get_tree().set_input_as_handled()


# Find the matching voice output file for the given key
#
# #### Parameters
#
# - key: Text key provided
# - start: Starting folder to search for voices
#
# *Returns* The path to the matching voice file
func _get_voice_file(key: String, start: String = "") -> String:
	if start == "":
		start = ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.SPEECH_FOLDER
		)
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
				if file_name == "%s.%s.import" % [
					key,
					ESCProjectSettingsManager.get_setting(
						ESCProjectSettingsManager.SPEECH_EXTENSION
					)
				]:
					return start.plus_file(file_name.trim_suffix(".import"))
			file_name = _dir.get_next()
	return ""


# Make a character say a text
#
# #### Parameters
#
# - character: Character that is talking
# - type: UI to use for the dialog
# - text: Text to say
func say(character: String, type: String, text: String) -> void:
	if type == "":
		type = ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE
		)
	is_speaking = true
	for _manager_class in ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	):
		if ResourceLoader.exists(_manager_class):
			var _manager: ESCDialogManager = load(_manager_class).new()
			if _manager.has_type(type):
				_dialog_manager = _manager
			else:
				_dialog_manager = null

	if _dialog_manager == null:
		escoria.logger.error(
			self,
			"No dialog manager called %s configured." % type
		)

	_dialog_manager.connect("say_finished", self, "_on_say_finished", [], CONNECT_ONESHOT)

	var matches = _keytext_regex.search(text)
	if not matches:
		escoria.logger.error(
			self,
			"Unexpected text encountered : %s." % text
		)
	var key = matches.get_string("key")
	if matches.get_string("key") != "":
		var _speech_resource = _get_voice_file(
			matches.get_string("key")
		)
		if _speech_resource == "":
			escoria.logger.warn(
				self,
				"Unable to find voice file with key '%s'." % matches.get_string("key")
			)		
		else:
			(
				escoria.object_manager.get_object(escoria.object_manager.SPEECH).node\
				 as ESCSpeechPlayer
			).set_state(_speech_resource)

		var translated_text: String = tr(matches.get_string("key"))

		# Only update the text if the translated text was found; otherwise, raise
		# a warning and use the original, untranslated text.
		if translated_text == matches.get_string("key"):
			escoria.logger.warn(
				self,
				"Unable to find translation key '%s'. Using untranslated text." % matches.get_string("key")
			)
			text = matches.get_string("text")
		else:
			text = translated_text
	else:
		text = matches.get_string("text")


	_dialog_manager.say(self, character, text, type)

# Handles the end of a say function after it has emitted say_finished.
func _on_say_finished():
	is_speaking = false
	emit_signal("say_finished")


# Called when a dialog line is skipped
func speedup() -> void:
	if is_speaking and escoria.inputs_manager.input_mode != \
			escoria.inputs_manager.INPUT_NONE and \
			_dialog_manager != null:
		_dialog_manager.speedup()


# Display a list of choices
#
# #### Parameters
#
# - dialog: The dialog to start
func start_dialog_choices(dialog: ESCDialog, type: String = "simple"):
	if dialog.options.empty():
		escoria.logger.error(
			self,
			"Received dialog options array was empty."
		)

	var _dialog_chooser_ui: ESCDialogManager = null

	for _manager_class in ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	):
		if ResourceLoader.exists(_manager_class):
			var _manager: ESCDialogManager = load(_manager_class).new()
			if _manager.has_chooser_type(type):
				_dialog_chooser_ui = _manager

	if _dialog_chooser_ui == null:
		escoria.logger.error(
			self,
			"No dialog manager supports the chooser type %s." % type
		)

	_dialog_chooser_ui.choose(self, dialog)
	var option = yield(_dialog_chooser_ui, "option_chosen")
	emit_signal("option_chosen", option)


# Interrupt the currently running dialog
func interrupt():
	if _dialog_manager != null:
		_dialog_manager.interrupt()
