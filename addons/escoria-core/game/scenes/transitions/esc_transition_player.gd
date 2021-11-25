# A transition player for scene changes
extends ColorRect
class_name ESCTransitionPlayer

# Emitted when the transition was played
signal transition_done(transition_id)

# Id of the transition. Allows keeping track of the actual transition 
# being played or finished
var transition_id: int = 0

# The valid transition modes
enum TRANSITION_MODE {
	IN,
	OUT
}


# The tween instance to animate
var _tween: Tween

# If the current tween was canceled
var _was_canceled: bool = false


# Fade in when the scene is starting
func _ready() -> void:
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	color = Color.white
	mouse_filter = MOUSE_FILTER_IGNORE
	_tween = Tween.new()
	add_child(_tween)
	_tween.connect("tween_all_completed", self, "_on_tween_completed")
	
	transition()


# Play a transition animation
#
# ## Parameters
# 
# - transition_name: name of the transition to play (if empty string, uses
# the default transition)
# - mode: Mode to transition (in/out)
# - duration: The duration the transition should take
func transition(
	transition_name: String = "", 
	mode: int = TRANSITION_MODE.IN,
	duration: float = 1.0
) -> int:
	if not has_transition(transition_name):
		escoria.logger.report_errors(
			"transition: Transition %s not found" % transition_name,
			[]
		)
	
	material = ResourceLoader.load(get_transition(transition_name))
	transition_id += 1
	
	var start = 0.0
	var end = 1.0
	
	if mode == TRANSITION_MODE.OUT:
		start = 1.0
		end = 0.0
	
	if _tween.is_active():
		_was_canceled = true
		_tween.stop_all()
		_tween.remove_all()
		emit_signal("transition_done", transition_id-1)
	
	_tween.interpolate_property(
		$".",
		"material:shader_param/cutoff",
		start,
		end,
		duration
	)
	_was_canceled = false
	_tween.start()
	return transition_id


# Returns the full path for a transition shader based on its name
#
# ## Parameters
#
# - name: The name of the transition to test
#
# *Returns* the full path to the shader or an empty string, if it can't be found
func get_transition(name: String) -> String:
	if name.empty():
		name = ProjectSettings.get_setting(
			"escoria/ui/default_transition"
		)
	for directory in ProjectSettings.get_setting("escoria/ui/transition_paths"):
		if ResourceLoader.exists(directory.plus_file("%s.material" % name)):
			return directory.plus_file("%s.material" % name)
	return ""


# Returns true whether the transition scene has a transition corresponding 
# to name provided.
#
# ## Parameters
#
# - name: The name of the transition to test
#
# *Returns* true if a transition exists with given name.
func has_transition(name: String) -> bool:
	return not get_transition(name) == ""
	

func _on_tween_completed():
	if not _was_canceled:
		_tween.stop_all()
		_tween.remove_all()
		escoria.logger.debug("Transition %s done." % str(transition_id))
		emit_signal("transition_done", transition_id)
