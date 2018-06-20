# angle "0" is facing the camera, rotates counter clock-wise, angle 90 is profile right, etc

const dir_angles = [0, 45, 90, 135, 180, 270, 360 ]


const directions = ["walk_right", 1,
					"walk_right", 1,
					"walk_up", 1,
					"walk_up", 1,
					"walk_right", -1,
					"walk_right", -1,
					"walk_down", 1,
					"walk_down", 1
					]

const idles = [	"idle_right", 1,
				"idle_right", 1,
				"idle_up", 1,
				"idle_up", 1,
				"idle_right", -1,
				"idle_right", -1,
				"idle_down", 1,
				"idle_down", 1
				]

const speaks = ["idle_right", 1, 
				"idle_right", 1,
				"idle_up", 1, 
				"idle_up", 1, 
				"idle_right", -1, 
				"idle_right", -1,
				"idle_down", 1, 
				"idle_down", 1]