# Describes a bounding box that limits the camera movement in the scene
extends Object
class_name ESCCameraLimits


# The left side of the bounding box
var limit_left: int = -10000

# The right side of the bounding box
var limit_right: int = 10000

# The top side of the bounding box
var limit_top: int = -10000

# The bottom side of the bounding box
var limit_bottom: int = 10000


func _init(
	left: int, 
	right: int, 
	top: int, 
	bottom: int
):
	limit_left = left
	limit_right = right
	limit_top = top
	limit_bottom = bottom
