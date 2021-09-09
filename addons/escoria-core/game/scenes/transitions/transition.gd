# A transition player for scene changes
extends ColorRect

# Emitted when the transition was played
signal transition_done


# The name of the default transition to play
export(
	String, 
	"fade_black", 
	"fade_white", 
	"curtain"
) var transition_name: String



# Reference to the _AnimationPlayer_ node
onready var _anim_player := $AnimationPlayer


# Fade in when the scene is starting
func _ready() -> void:
	transition_in()


# Transition out 
#
# ## Parameters
# 
# - p_transition_name: name of the transition to play (if empty string, uses
# the default transition)
func transition_out(p_transition_name: String = "") -> void:
	if p_transition_name.empty():
		_anim_player.play_backwards(transition_name)
	else:
		_anim_player.play_backwards(p_transition_name)
	yield(_anim_player, "animation_finished")
	emit_signal("transition_done")
	_anim_player.seek(0.0)

	
# Transition in
#
# ## Parameters
# 
# - p_transition_name: name of the transition to play (if empty string, uses
# the default transition)
func transition_in(p_transition_name: String = "") -> void:
	if p_transition_name.empty():
		_anim_player.play(transition_name)
	else:
		_anim_player.play(p_transition_name)
	yield(_anim_player, "animation_finished")
	emit_signal("transition_done")
	_anim_player.seek(0.0)


# Returns true whether the transition scene has a transition corresponding 
# to name provided.
#
# ## Parameters
#
# - p_name: The name of the transition to test
#
# *Returns* true if a transition exists with given name.
func has_transition(p_name: String) -> bool:
	return _anim_player.has_animation(p_name)
