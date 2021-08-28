# A playable character
tool
extends ESCItem
class_name ESCPlayer, "res://addons/escoria-core/design/esc_player.svg"


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
