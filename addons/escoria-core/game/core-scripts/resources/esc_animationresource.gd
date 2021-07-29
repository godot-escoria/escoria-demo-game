# Resource containing all defined animations and angles for 
# characters movement.
 
extends Resource
class_name ESCAnimationResource


# Array containing the different angles available for animations.
# Each angle is defined by an array [start_angle, angle_size].
# start_angle must be between 0 and 360.
# Angle 0 and 360 are the same and correspond to UP/NORTH
# 90 is RIGHT/EAST, 180 is DOWN/SOUTH, etc
export(Array) var dir_angles = []

# Array of animations for each direction, from UP to RIGHT_UP clockwise
# [animation_name, scale]: scale parameter can be set to -1 to mirror 
# the animation
export(Array) var directions = []


# Array containing the idle animations for each direction (in the
# order defined by dir_angles): scale parameter can be set to -1 to mirror 
# the animation
export(Array) var  idles = []

# Array containing the speak animations for each direction (in the
# order defined by dir_angles): scale parameter can be set to -1 to mirror 
# the animation
export(Array) var speaks = []
