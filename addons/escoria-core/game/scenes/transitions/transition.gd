# A transition player for scene changes
# FIXME Add configuration to select a specific mask
extends ColorRect


# Emitted when the transition was player
signal transition_done


# The name of the transition to play
export(
	String, 
	"fade_black", 
	"fade_white", 
	"transition_in", 
	"transition_out"
) var transition_name: String


# Reference to the _AnimationPlayer_ node
onready var _anim_player := $AnimationPlayer


# Fade in when the scene is starting
func _ready() -> void:
	fade_in()


# Fade out the transition
func fade_out() -> void:
	_anim_player.play(transition_name)
	yield(_anim_player, "animation_finished")
	emit_signal("transition_done")


# Fade in the transition
func fade_in() -> void:
	# Plays the Fade animation and wait until it finishes
	_anim_player.play_backwards(transition_name)
	yield(_anim_player, "animation_finished")
	emit_signal("transition_done")
