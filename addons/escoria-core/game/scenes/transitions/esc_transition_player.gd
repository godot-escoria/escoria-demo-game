## A transition player for scene changes
extends ColorRect
class_name ESCTransitionPlayer

## Emitted when the transition was played
signal transition_done(transition_id)

## The valid transition modes
enum TRANSITION_MODE {
	IN,
	OUT
}

## Id to represent instant/no transitions
const TRANSITION_ID_INSTANT = -1

## Instant transition type
const TRANSITION_INSTANT = "instant"

## Id of the transition. Allows keeping track of the actual transition
## being played or finished
var transition_id: int = 0

## The tween instance to animate
var _tween: Tween3

## If the current tween was canceled
var _was_canceled: bool = false

## Fade in when the scene is starting
func _ready() -> void:
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	color = Color.WHITE
	color.a = 0
	mouse_filter = MOUSE_FILTER_IGNORE
	_tween = Tween3.new(self)

## Play a transition animation[br]
## [br]
## #### Parameters[br]
## [br]
## - transition_name: Name of the transition to play (if empty string, uses[br]
##   the default transition).[br]
## - mode: Mode to transition (in/out).[br]
## - duration: The duration the transition should take.[br]
## [br]
## Returns the transition id.
func transition(
	transition_name: String = "",
	mode: int = TRANSITION_MODE.IN,
	duration: float = 1.0
) -> int:

	# We put this here instead of the constructor since if we have it in the
	# constructor, the transition will ALWAYS happen on game start, which might
	# not be desired if 'false' is used for automatic_transitions in a
	# change_scene call in :init.
	if not _tween.finished.is_connected(_on_tween_completed):
		_tween.finished.connect(_on_tween_completed)

	if transition_name.is_empty():
		transition_name = ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.DEFAULT_TRANSITION
		)

	if not has_transition(transition_name):
		escoria.logger.error(
			self,
			"transition: Transition %s not found" % transition_name
		)

	# If this is an "instant" transition, we need to set the alpha of the base
	# ColorRect to 0, since the transition materials used have a final state
	# that sets this scene's root (ColorRect) alpha to 0.
	if transition_name == TRANSITION_INSTANT:
		color.a = 0
		return TRANSITION_ID_INSTANT

	var material_path = get_transition(transition_name)

	material = ResourceLoader.load(get_transition(transition_name))
	transition_id += 1

	var start = 0.0
	var end = 1.0

	if mode == TRANSITION_MODE.OUT:
		start = 1.0
		end = 0.0

	if _tween.is_running():
		_was_canceled = true
		_tween.stop()
		_tween.reset()
		transition_done.emit(transition_id-1)

	_tween.interpolate_property(
		$".",
		"material:shader_parameter/cutoff",
		start,
		end,
		duration
	)
	_was_canceled = false
	_tween.play()
	return transition_id


## Returns the full path for a transition shader based on its name[br]
## [br]
## #### Parameters[br]
## [br]
## - name: The name of the transition to test.[br]
## [br]
## Returns the full path to the shader or an empty string if it can't be found.
func get_transition(name: String) -> String:
	for directory in ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.TRANSITION_PATHS
	):
		if ResourceLoader.exists(directory.path_join("%s.material" % name)):
			return directory.path_join("%s.material" % name)
	return ""


## Returns true whether the transition scene has a transition corresponding[br]
## to name provided.[br]
## [br]
## #### Parameters[br]
## [br]
## - name: The name of the transition to test.[br]
## [br]
## Returns true if a transition exists with given name.
func has_transition(name: String) -> bool:
	return name == TRANSITION_INSTANT or get_transition(name) != ""


## Resets the current material's cutoff parameter instantly.
func reset_shader_cutoff() -> void:
	if not is_instance_valid(material):
		return

	material.set_shader_parameter("cutoff", 1.0)


## Called when the tween completes the transition.
func _on_tween_completed():
	if not _was_canceled:
		_tween.stop()
		_tween.reset()
		escoria.logger.debug(self, "Transition %s done." % str(transition_id))
		transition_done.emit(transition_id)
