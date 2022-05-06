# An ESC dialog
extends ESCStatement
class_name ESCDialog


# Regex that matches dialog lines
const REGEX = \
	'^(\\s*)\\?( (?<avatar>[^ ]+))?' +\
	'( (?<timeout>[^ ]+))?( (?<timeout_option>.+))?$'


# A Regex that matches the end of a dialog
const END_REGEX = \
	'^(?<indent>\\s*)!.*$'


# Avatar used in the dialog
var avatar: String = "-"

# Timeout until the timeout_option option is selected. Use 0 for no timeout
var timeout: int = 0

# The dialog option to select when timeout is reached
var timeout_option: int = 0

# A list of ESCDialogOptions
var options: Array


# Construct a dialog from an ESC dialog string
#
# #### Parameters
# - dialog_string: ESC dialog string
func load_string(dialog_string: String):
	var dialog_regex = RegEx.new()
	dialog_regex.compile(REGEX)

	if dialog_regex.search(dialog_string):
		for result in dialog_regex.search_all(dialog_string):
			if "avatar" in result.names:
				self.avatar = ESCUtils.get_re_group(result, "avatar")
			if "timeout" in result.names:
				self.timeout = int(
					ESCUtils.get_re_group(result, "timeout")
				)
			if "timeout_option" in result.names:
				self.timeout_option = int(
					ESCUtils.get_re_group(result, "timeout_option")
				)
	else:
		escoria.logger.error(
			self,
			"Invalid dialog detected: %s\nDialog regexp didn't match" 
					% dialog_string
		)


# Check if dialog is valid
func is_valid() -> bool:
	if self.avatar != "-" and not ResourceLoader.exists(self.avatar):
		escoria.logger.error(
			self,
			"Avatar scene not found: %s" % self.avatar
		)
		return false
	if self.timeout_option > self.options.size() \
			or self.timeout_option < 0:
		escoria.logger.error(
			self,
			"Invalid timeout_option parameter given: %d" % self.timeout_option
		)
		return false

	return true


# Run this dialog
func run():
	escoria.logger.debug(
		self,
		"Starting dialog"
	)
	escoria.current_state = escoria.GAME_STATE.DIALOG
	if !escoria.dialog_player:
		escoria.dialog_player = escoria.main.current_scene.get_node(
			"game/ui/dialog_layer/dialog_player"
		)
	escoria.dialog_player.start_dialog_choices(self)
	var option = yield(
		escoria.dialog_player,
		"option_chosen"
	) as ESCDialogOption
	var rc = option.run()
	if rc is GDScriptFunctionState:
		rc = yield(rc, "completed")
	if rc != ESCExecution.RC_CANCEL:
		return self.run()
	return rc
