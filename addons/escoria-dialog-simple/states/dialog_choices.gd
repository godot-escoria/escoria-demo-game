extends State
class_name DialogChoices


# The owning dialog player.
var _dialog_player

# The dialog to start.
var _dialog: ESCDialog
var _type: String = "simple"

var _dialog_chooser_ui: ESCDialogManager = null

var _ready_to_choose: bool


func initialize(dialog_player, dialog_chooser_ui: ESCDialogManager, dialog: ESCDialog, type: String) -> void:
	_dialog_player = dialog_player
	_dialog_chooser_ui = dialog_chooser_ui
	_dialog = dialog
	_type = type


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'choices'.")

	if _dialog.options.empty():
		escoria.logger.error(
			self,
			"Received dialog options array was empty."
		)

	_ready_to_choose = true


func update(_delta):
	if _ready_to_choose:
		_ready_to_choose = false
		_dialog_chooser_ui.do_choose(_dialog_player, _dialog, _type)
		var option = yield(_dialog_chooser_ui, "option_chosen")

		escoria.logger.trace(self, "Dialog State Machine: 'choices' -> 'idle'")

		emit_signal("finished", "idle")
		_dialog_player.emit_signal("option_chosen", option)
