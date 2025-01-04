# An abstraction class to expose the same animation methods for noth
# AnimatedSprite and AnimationPlayer
extends Node
class_name ESCAnimationPlayer


# Emitted when the animation finsihed playing
signal animation_finished(name)


# The actual player node
var _player_node: Node

# A AnimationPlayer typed reference to the player node (for intellisense)
var _animation_player: AnimationPlayer

# A AnimationPlayer typed reference to the player node (for intellisense)
var _animated_sprite: AnimatedSprite2D

# Whether the player node is of type AnimationPlayer (just for convenience)
var _is_animation_player: bool = false

# Currently running animation
var _current_animation: String = ""


# Create a new animation player
#
# #### Parameters
#
# - node: The actual player node
func _init(node: Node):
	_player_node = node
	if node is AnimationPlayer:
		_is_animation_player = true
		_animation_player = node
	else:
		_animated_sprite = node
	node.add_child(self)


# Connect animation signals
func _ready() -> void:
	if _is_animation_player:
		_player_node.animation_finished.connect(_on_animation_finished)
	else:
		_player_node.animation_finished.connect(_on_animation_finished_animated_sprite)


# Return the currently playing animation
# **Returns** the currently playing animation name
func get_animation() -> String:
	if _is_animation_player:
		return _animation_player.assigned_animation
	else:
		return _animated_sprite.animation


# Returns a list of all animation names
# **Returns** A list of all animation names
func get_animations() -> PackedStringArray:
	if _is_animation_player:
		return _animation_player.get_animation_list()
	else:
		return _animated_sprite.frames.get_animation_names()


# Whether the animation is playing
# **Returns: Whether the animation is playing**
func is_playing() -> bool:
	return _player_node.is_playing()


# Stop the animation
func stop():
	_player_node.stop()


# Play the animation
#
# #### Parameters
#
# - name: The animation name to play
# - backwards: Play backwards
func play(name: String, backwards: bool = false):
	if _is_animation_player and _animation_player.current_animation != "":
		_animation_player.seek(0)
	elif not _is_animation_player:
		_animated_sprite.frame = 0

	_current_animation = name

	if backwards and _is_animation_player:
		_animation_player.play_backwards(name)
	elif backwards:
		_animated_sprite.play(name, true)
	else:
		_player_node.play(name)

		# Instead of waiting for the next frame, start the animation now.
		if _is_animation_player:
			_player_node.advance(0)


# Play the given animation backwards
#
# #### Parameters
#
# - name: Animation to play
func play_backwards(name: String):
	self.play(name, true)


# Check if the given animation exists
#
# #### Parameters
#
# - name: Name of the animation to check
# **Returns** Whether the animation player has the animation
func has_animation(name: String) -> bool:
	if _is_animation_player:
		return _animation_player.has_animation(name)
	else:
		return _animated_sprite.sprite_frames.has_animation(name)


# Play an animation and directly skip to the end
#
# #### Parameters
#
# - name: Name of the animation to play
func seek_end(name: String):
	if _is_animation_player:
		_animation_player.current_animation = name
		_animation_player.seek(_animation_player.get_animation(name).length, true)
	else:
		_animated_sprite.animation = name
		_animated_sprite.frame = _animated_sprite.frames.get_frame_count(name)


# Get the length of the specified animation
#
# #### Parameters
#
# - name: Name of the animation
# **Returns** The length of the animation in seconds
func get_length(name: String) -> float:
	if _is_animation_player:
		return _animation_player.get_animation(name).length
	else:
		return _animated_sprite.frames.get_frame_count(name) - 1 * \
				_animated_sprite.frames.get_animation_speed(name)


# Return true if the ESCAnimationPlayer node is valid, ie. it has a valid player
# node.
# **Returns: true if the ESCAnimationPlayer has a valid player node,
# else false**
func is_valid() -> bool:
	return _player_node != null and _player_node is Node


# Transport the animation_finished signal
#
# #### Parameters
#
# - name: Name of the animation played
func _on_animation_finished(name: String):
	if _is_animation_player and not _animation_player.get_animation(name).loop_mode != Animation.LOOP_NONE:
		_animation_player.stop(true) # param here is to keep current state and
									 # avoid resetting animation position to 0  
	elif not _animated_sprite.frames.get_animation_loop(name):
		_animated_sprite.stop()
	animation_finished.emit(name)


# Special signal handler for animated sprites
func _on_animation_finished_animated_sprite():
	_on_animation_finished(_current_animation)
