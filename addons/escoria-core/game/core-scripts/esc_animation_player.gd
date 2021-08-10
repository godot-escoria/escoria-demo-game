# An abstraction class to expose the same animation methods for noth
# AnimatedSprite and AnimationPlayer
extends Node
class_name ESCAnimationPlayer


signal animation_finished(name)


# The actual player node
var _player_node: Node

# A AnimationPlayer typed reference to the player node (for intellisense)
var _animation_player: AnimationPlayer

# A AnimationPlayer typed reference to the player node (for intellisense)
var _animated_sprite: AnimatedSprite

# Wether the player node is of type AnimationPlayer (just for convenience)
var _is_animation_player: bool = false


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


# Return the currently playing animation
# **Returns** the currently playing animation name
func get_animation() -> String:
	if _is_animation_player:
		return _animation_player.current_animation
	else:
		return _animated_sprite.animation


# Returns a list of all animation names
# **Returns** A list of all animation names
func get_animations() -> PoolStringArray:
	if _is_animation_player:
		return _animation_player.get_animation_list()
	else:
		return _animated_sprite.frames.get_animation_names()


# Wether the animation is playing
# **Returns: Wether the animation is playing**
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
	if _player_node.is_connected(
		"animation_finished",
		self,
		"_on_animation_finished"
	):
		_player_node.disconnect(
			"animation_finished",
		self,
		"_on_animation_finished"
		)
	_player_node.connect(
		"animation_finished",
		self,
		"_on_animation_finished",
		[name]
	)
	if backwards and _is_animation_player:
		_animation_player.play_backwards(name)
	elif backwards:
		_animated_sprite.play(name, true)
	else:
		_player_node.play(name)
	

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
# **Returns** Wether the animation player has the animation
func has_animation(name: String) -> bool:
	if _is_animation_player:
		return _animation_player.has_animation(name)
	else:
		return _animated_sprite.frames.has_animation(name)


# Play an animation and directly skip to the end
#
# #### Parameters
#
# - name: Name of the animation to play
func seek_end(name: String):
	if _is_animation_player:
		_animation_player.current_animation = name
		_animation_player.seek(_animation_player.get_animation(name).length)
	else:
		_animated_sprite.animation = name
		_animated_sprite.frame = _animated_sprite.frames.get_frame_count(name)


# Transport the animation_finished signal
#
# #### Parameters
#
# - name: Name of the animation played
func _on_animation_finished(name: String):
	emit_signal("animation_finished", name)
