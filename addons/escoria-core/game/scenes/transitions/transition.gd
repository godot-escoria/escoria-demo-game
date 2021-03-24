extends ColorRect

export(String, "fade_black", "fade_white", "transition_in", "transition_out") var transition_name
# Reference to the _AnimationPlayer_ node
onready var _anim_player := $AnimationPlayer



signal transition_done


func _ready() -> void:
	# Plays the animation backward to fade in
	_anim_player.play_backwards(transition_name)


func fade_out() -> void:
	# Plays the Fade animation and wait until it finishes
	_anim_player.play(transition_name)
	yield(_anim_player, "animation_finished")
	emit_signal("transition_done")

func fade_in() -> void:
	# Plays the Fade animation and wait until it finishes
	_anim_player.play_backwards(transition_name)
	yield(_anim_player, "animation_finished")
	emit_signal("transition_done")

