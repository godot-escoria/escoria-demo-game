# The walk context describes the target of a walk command and if that command
# should be executed fast
extends Object
class_name ESCWalkContext


# Target object that the walk command tries to reach
var target_object: ESCObject = null

# The target position
var target_position: Vector2 = Vector2()

# Wether to move fast
var fast: bool


func _init(
	p_target_object: ESCObject, 
	p_target_position: Vector2,  
	p_fast: bool
):
	target_object = p_target_object
	target_position = p_target_position
	fast = p_fast
