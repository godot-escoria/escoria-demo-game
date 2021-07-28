# A playable character
# TODO
# - Currently the sprite node needs to be named "sprite". This is bad.
# - Animation management doesn't allow using AnimationPlayer yet. Need to find 
#  the best solution to manage both AnimatedSprite and AnimationPlayer.
tool
extends ESCItem
class_name ESCPlayer


# The node that references the camera position
export(NodePath) var camera_position_node


# A player is always movable
func _init():
	is_movable = true


# Ready function
func _ready():
	# For ESCPlayer, avoid the CollisionShape2D used for movement to catch inputs
	disconnect("input_event", self, "manage_input")


# Return the camera position if a camera_position_node exists or the
# global position of the player
func get_camera_pos():
	if camera_position_node and get_node(camera_position_node):
		return get_node(camera_position_node).global_position
	return global_position
