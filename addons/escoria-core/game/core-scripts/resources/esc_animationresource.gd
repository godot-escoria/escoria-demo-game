# Resource containing all defined animations and angles for
# characters movement.
tool
extends Resource
class_name ESCAnimationResource


# Array containing the different angles available for animations.
# Each angle is defined by an array [start_angle, angle_size].
# start_angle must be between 0 and 360.
# Angles 0 and 360 are the same and correspond to UP/NORTH,
# 90 is RIGHT/EAST, 180 is DOWN/SOUTH, 270 is LEFT/WEST etc.
export(Array, Resource) var dir_angles: Array = [] setget set_dir_angles

# Array of animations for each direction, from UP to RIGHT_UP clockwise
# [animation_name, scale]: scale parameter can be set to -1 to mirror
# the animation
export(Array, Resource) var directions: Array = [] setget set_directions

# Array containing the idle animations for each direction (in the
# order defined by dir_angles): scale parameter can be set to -1 to mirror
# the animation
export(Array, Resource) var idles: Array = [] setget set_idles

# Array containing the speak animations for each direction (in the
# order defined by dir_angles): scale parameter can be set to -1 to mirror
# the animation
export(Array, Resource) var speaks: Array = [] setget set_speaks


# Sets the dir_angles property.
#
# #### Parameters
#
# - p_dir_angles: array of direction angle resources to set.
func set_dir_angles(p_dir_angles: Array) -> void:
	dir_angles = p_dir_angles
	emit_changed()


# Sets the directions property.
#
# #### Parameters
#
# - p_directions: array of direction resources to set.
func set_directions(p_set_directions: Array) -> void:
	directions = p_set_directions
	emit_changed()


# Sets the idles property.
#
# #### Parameters
#
# - p_set_idles: array of idle resources to set.
func set_idles(p_set_idles: Array) -> void:
	idles = p_set_idles
	emit_changed()


# Sets the speaks property.
#
# #### Parameters
#
# - p_set_idles: array of speak resources to set.
func set_speaks(p_set_speaks: Array) -> void:
	speaks = p_set_speaks
	emit_changed()
