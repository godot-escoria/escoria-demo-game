## Represents a dialog in Escoria.
extends ESCStatement
class_name ESCDialog


## Avatar used in the dialog, if any.
var avatar: String = "-"

## Timeout until the timeout_option option is selected. Use 0 for no timeout.
var timeout: int = 0

## The dialog option to select when timeout is reached.
var timeout_option: int = 0

## A list of `ESCDialogOption`s.
var options: Array


## True iff the dialog and its settings are valid.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns true iff the dialog and its settings are valid. (`bool`)
func is_valid() -> bool:
	if self.avatar != "-" and not ResourceLoader.exists(self.avatar):
		escoria.logger.error(
			self,
			"Avatar scene not found: %s." % self.avatar
		)
		return false
	if self.timeout_option > self.options.size() \
			or self.timeout_option < 0:
		escoria.logger.error(
			self,
			"Invalid timeout_option parameter given: %d." % self.timeout_option
		)
		return false

	return true


## Run this dialog. TODO: Although this method overrides its parent version, the return type here does NOT match the parent's signature. Consider either changing the parent's return type to be a `Variant`, or doing something to ensure greater consistency.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the `ESCDialogOption` chosen by the player. (`Variant`)
func run():
	escoria.logger.debug(
		self,
		"Starting dialog."
	)

	escoria.current_state = escoria.GAME_STATE.DIALOG

	if !escoria.dialog_player:
		escoria.dialog_player = escoria.main.current_scene.get_node(
			"game/ui/dialog_layer/dialog_player"
		)

	escoria.dialog_player.start_dialog_choices(self)

	var option = (
		await escoria.dialog_player.option_chosen
	) as ESCDialogOption

	# If no valid option was returned, it means this level of dialog is done.
	# If this is the case and the current level of dialog has a parent, it means
	# it is still yielding and so will be shown again.

	escoria.current_state = escoria.GAME_STATE.DEFAULT

	return option
