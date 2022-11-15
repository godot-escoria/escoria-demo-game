extends State
class_name DialogChoices


# The owning dialog player.
var _dialog_player

# The dialog to start.
var _dialog: ESCDialog
var _type: String = "simple"

var _dialog_chooser_ui: ESCDialogManager = null

var _ready_to_choose: bool


func initialize(dialog_player, dialog: ESCDialog, type: String) -> void:
	_dialog_player = dialog_player
	_dialog = dialog
	_type = type


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'choices'.")

	if _dialog.options.empty():
		escoria.logger.error(
			self,
			"Received dialog options array was empty."
		)

	for _manager_class in ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	):
		if ResourceLoader.exists(_manager_class):
			var _manager: ESCDialogManager = load(_manager_class).new()
			if _manager.has_chooser_type(_type):
				_dialog_chooser_ui = _manager

	if _dialog_chooser_ui == null:
		escoria.logger.error(
			self,
			"No dialog manager supports the chooser type %s." % _type
		)

	_ready_to_choose = true


func update(_delta):
	if _ready_to_choose:
		_ready_to_choose = false
		_dialog_chooser_ui.choose(self, _dialog)
		var option = yield(_dialog_chooser_ui, "option_chosen")

		escoria.logger.trace(self, "Dialog State Machine: 'choices' -> 'idle'")

		emit_signal("finished", "idle")
		_dialog_player.emit_signal("option_chosen", option)
