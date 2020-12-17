#const dir_angles = [
#	0, 		# 0	NORTH	FACE CAMERA
#	45, 	# 1 NORTHEAST
#	90, 	# 2	EAST
#	135, 	# 3 SOUTHEAST
#	180, 	# 4	SOUTH	BACK TO CAMERA
#	225, 	# 5 SOUTHWEST
#	270, 	# 6	WEST
#	315, 	# 7 NORTHWEST
#]

# Angle is [from_angle, area_angle]
# example : on a clock, [180, 45] starts exactly from 6 o'clock (180°) 
# and stops between 7 o'clock and 8 o'clock (45° from 6 o'clock)
const dir_angles = [
	[340, 40], 		# 0 UP
	[20, 50], 		# 1 RIGHT UP
	[70, 40], 		# 2 RIGHT
	[110, 50], 		# 3 RIGHT DOWN
	[160, 40], 		# 4 DOWN
	[200, 50], 		# 5 LEFT DOWN
	[250, 40], 		# 6 LEFT
	[290, 50]		# 7 LEFT UP
]

# Array of animations for each direction, from UP to RIGHT_UP clockwise
# [animation_name, scale] : scale parameter can be set to -1 to mirror the animation
const directions = [
	["walk_back", 1],			# 0 UP
	["walk_back_left", -1],		# 1 RIGHT UP
	["walk_left", -1],			# 2 RIGHT
	["walk_front_left", -1],	# 3 RIGHT DOWN
	["walk_front", 1],			# 4 DOWN
	["walk_front_left", 1],		# 5 LEFT DOWN
	["walk_left", 1],			# 6 LEFT
	["walk_back_left", 1]		# 7 LEFT UP
]

const idles = [
	["idle_back", 1],			# 0 UP
	["idle_back_right", 1],		# 1 RIGHT UP
	["idle_front_right", 1],	# 2 RIGHT
	["idle_front_right", 1],	# 3 RIGHT DOWN
	["idle_front", 1],			# 4 DOWN
	["idle_front_left", 1],		# 5 LEFT DOWN
	["idle_front_left", 1],		# 6 LEFT
	["idle_back_left", 1]		# 7 LEFT UP
]

const speaks = [
	["idle_front_left", 1],		# 0
	["idle_front_left", 1],		# 1
	["idle_back", 1],			# 2
	["idle_back", 1],			# 3
	["idle_front_right", 1],	# 4
	["idle_front_right", 1],	# 5
	["idle_front", 1],			# 6
	["idle_front", 1]			# 7
]
				
				
#const directions = ["walk_left", -1,	# 0
#					"walk_left", -1,	# 1
#					"walk_back", 1,		# 2
#					"walk_back", 1,		# 3
#					"walk_left", 1,		# 4
#					"walk_left", 1,		# 5
#					"walk_front", 1,	# 6
#					"walk_front", 1		# 7
#					]
#
#const idles = [	"idle_front_right", 1,	# 0
#				"idle_front_right", 1,	# 1
#				"idle_back", 1,			# 2
#				"idle_back", 1,			# 3
#				"idle_front_left", 1,	# 4
#				"idle_front_left", 1,	# 5
#				"idle_front", 1,		# 6
#				"idle_front", 1			# 7
#				]
#
#const speaks = ["idle_front_left", 1,	# 0
#				"idle_front_left", 1,	# 1
#				"idle_back", 1,			# 2
#				"idle_back", 1,			# 3
#				"idle_front_right", 1,	# 4
#				"idle_front_right", 1,	# 5
#				"idle_front", 1,		# 6
#				"idle_front", 1			# 7
#				]
