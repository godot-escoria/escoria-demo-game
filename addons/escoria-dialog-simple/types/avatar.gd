# A dialog GUI showing a dialog box and character portraits
extends Popup


# Signal emitted when text has been said
signal say_finished


# The text speed per character for normal display
var _text_speed_per_character

# The text speed per character if the dialog line is skipped
var _fast_text_speed_per_character

# The time to wait before the dialog is finished
var _max_time_to_text_disappear

# Whether the current dialog is speeding up
var _is_speeding_up: bool = false


# The node holding the avatar
onready var avatar_node = $Panel/MarginContainer/HSplitContainer/VBoxContainer\
		/avatar

# The node showing the text
onready var text_node = $Panel/MarginContainer/HSplitContainer/text

# The tween node for text animations
onready var tween = $Panel/MarginContainer/HSplitContainer/text/Tween

# Whether the dialog manager is paused
onready var is_paused: bool = true



# Build up the UI
func _ready():
	_text_speed_per_character = ProjectSettings.get_setting(
		"escoria/dialog_simple/text_speed_per_character"
	)
	_fast_text_speed_per_character = ProjectSettings.get_setting(
		"escoria/dialog_simple/fast_text_speed_per_character"
	)
	_max_time_to_text_disappear = ProjectSettings.get_setting(
		"escoria/dialog_simple/max_time_to_disappear"
	)
	text_node.bbcode_enabled = true
	tween.connect(
		"tween_completed",
		self,
		"_on_dialog_line_typed"
	)

	escoria.connect("paused", self, "_on_paused")
	escoria.connect("resumed", self, "_on_resumed")


# Switch the current character
#
# #### Parameters
# - name: The name of the current character
func set_current_character(name: String):
	if ProjectSettings.get_setting("escoria/dialog_simple/avatars_path").empty():
		escoria.logger.warn(self, "Unable to load avatar '%s': Avatar path not specified" % name)
		return

	var avatar = "%s/%s.tres" % [
		ProjectSettings.get_setting("escoria/dialog_simple/avatars_path"),
		name
	]
	if ResourceLoader.exists(avatar):
		avatar_node.texture = ResourceLoader.load(avatar)
	else:
		escoria.logger.warn(self, "Unable to load avatar '%s': Resource not found in path '%s'" %
			[name, ProjectSettings.get_setting("escoria/dialog_simple/avatars_path")])


# Make a character say something
#
# #### Parameters
# - character: The global id of the character speaking
# - line: Line to say
func say(character: String, line: String):
	_is_speeding_up = false
	popup_centered()
	set_current_character(character)

	text_node.bbcode_text = tr(line)

	text_node.percent_visible = 0.0
	var time_show_full_text = _text_speed_per_character * len(line)

	tween.interpolate_property(text_node, "percent_visible",
		0.0, 1.0, time_show_full_text,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


# Called by the dialog player when the
func speedup():
	if not _is_speeding_up:
		_is_speeding_up = true
		tween.remove_all()
		tween.interpolate_property(text_node, "percent_visible",
			text_node.percent_visible, 1.0, _fast_text_speed_per_character,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()


# The dialog line was printed, start the waiting time and then finish
# the dialog
func _on_dialog_line_typed(object, key):
	text_node.visible_characters = -1
	$Timer.start(_max_time_to_text_disappear)
	$Timer.connect("timeout", self, "_on_dialog_finished")


# Ending the dialog
func _on_dialog_finished():
	emit_signal("say_finished")
	queue_free()


# Handler managing pause notification from Escoria
func _on_paused():
	if tween.is_active():
		is_paused = true
		tween.stop_all()


# Handler managing resume notification from Escoria
func _on_resumed():
	if not tween.is_active():
		is_paused = false
		tween.resume_all()
