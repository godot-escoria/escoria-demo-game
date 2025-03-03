extends Node2D

# This scenes purpose is to help determining the angles between X and Y axis
# when clicking somewhere on the screen.
# Let us consider that player position is always 0,0.
# Clicking right above his head is angle 0.
# Clicking on the right is angle 90.
# Clicking under his feet is angle 180.
# etc.

var number_of_directions: int
var angle_horizontal_axes: float
var angle_vertical_axes: float
var angle_diagonal_axes: float
const POLYGON_DISTANCE = 400

enum Directions {
	NORTH, 		# 0
	NORTHEAST, 	# 1
	EAST, 		# 2
	SOUTHEAST, 	# 3
	SOUTH, 		# 4
	SOUTHWEST, 	# 5
	WEST,	 	# 6
	NORTHWEST 	# 7
}

const starting_angles = [
	0,			# 0 NORTH
	PI/4,		# 1 NORTHEAST
	PI/2,		# 2 EAST
	3*PI/4,		# 3 SOUTHEAST
	PI,			# 4 SOUTH
	5*PI/4,		# 5 SOUTHWEST
	3*PI/2,		# 6 WEST
	7*PI/4,		# 7 NORTHWEST
]

var colors = [
	Color("red"),		# 0 NORTH
	Color("green"),	# 1 NORTHEAST
	Color("blue"),		# 2 EAST
	Color("black"),	# 3 SOUTHEAST
	Color("yellow"),	# 4 SOUTH
	Color("cyan"),		# 5 SOUTHWEST
	Color("white"),	# 6 WEST
	Color("purple")	# 7 NORTHWEST
]

var result_angles = []

#onready var result_angles_anim = {
#		"angle_offset_rad": PI/2,
#		Directions.NORTH: {
#			"direction_base_angle_rad": 0,
#			"angle_start_deg": 0,
#			"angle_area_deg": 0,
#			"animations": {}
#		},
#		Directions.NORTHEAST: {
#			"direction_base_angle_rad": PI/4,
#			"angle_start_deg": 0,
#			"angle_area_deg": 0,
#			"animation": ""
#		},
#		Directions.EAST: {
#			"direction_base_angle_rad": PI/2,
#			"angle_start_deg": 0,
#			"angle_area_deg": 0,
#			"animation": ""
#		},
#		Directions.SOUTHEAST: {
#			"direction_base_angle_rad": 3*PI/4,
#			"angle_start_deg": 0,
#			"angle_area_deg": 0,
#			"animation": ""
#		},
#		Directions.SOUTH: {
#			"direction_base_angle_rad": PI,
#			"angle_start_deg": 0,
#			"angle_area_deg": 0,
#			"animation": ""
#
#		},
#		Directions.SOUTHWEST: {
#			"direction_base_angle_rad": 5*PI/4,
#			"angle_start_deg": 0,
#			"angle_area_deg": 0,
#			"animation": ""
#		},
#		Directions.WEST: {
#			"direction_base_angle_rad": 3*PI/2,
#			"angle_start_deg": 0,
#			"angle_area_deg": 0,
#			"animation": ""
#		},
#		Directions.NORTHWEST: {
#			"direction_base_angle_rad": 7*PI/4,
#			"angle_start_deg": 0,
#			"angle_area_deg": 0,
#			"animation": ""
#		}
#	}



func _ready():
	# Find player animations
	$player_animations.add_item("")
	for anim_name in $player.get_animation_player().get_animations():
		$player_animations.add_item(anim_name)

	# Set initial angles
	var initial_angle: float = 360.0 / 8.0
	$VBoxContainer/angle_x/angle_horiz.text = str(40)
	$VBoxContainer/angle_y/angle_vert.text = str(40)
	$VBoxContainer/angle_diag/angle_diag.text = str(50)
	angle_horizontal_axes = 40
	angle_vertical_axes = 40
	angle_diagonal_axes = 50

	calculate_areas()


func _on_number_of_directions_text_changed(new_text: String):
	if !new_text.is_valid_int():
		return
	number_of_directions = int(new_text)
	calculate_areas(number_of_directions)


func clear_areas_node():
	for n in $areas.get_children():
		n.queue_free()


func calculate_areas(nb_directions: int = 8):
	clear_areas_node()
	var angles = []
	for i in range(nb_directions):
		var angle_area: float = 0.0
		var start_angle: float = 0.0
		# MANUAL
		match i:
			Directions.EAST,Directions.WEST:
				angle_area = deg_to_rad(angle_horizontal_axes)
			Directions.NORTH,Directions.SOUTH:
				angle_area = deg_to_rad(angle_vertical_axes)
			Directions.NORTHEAST,Directions.NORTHWEST,Directions.SOUTHEAST,Directions.SOUTHWEST:
				angle_area = deg_to_rad(angle_diagonal_axes)

		# Since angles start from EAST, offset by -PI/2 (= -90°) to start on up direction
		# Then minus angle_area/2 to align on direction
		start_angle = PI/2 + angle_area / 2

		var angle_start = starting_angles[i] - start_angle
		var angle_end = angle_start + angle_area
		angles.push_back([angle_start, angle_end])

		result_angles.push_back([clamp360(rad_to_deg(angle_start) + rad_to_deg(PI/2)),clamp360(rad_to_deg(angle_area))])

	$VBoxContainer/VBoxContainer/angles/angle_array.text = str(result_angles)
	construct_scene_nodes(angles)


func construct_scene_nodes(angles):
	var areas_nodes = []
	for i in angles.size():
			var polygon_node = Polygon2D.new()
			polygon_node.color = colors[i]
			var area_node = Area2D.new()
			area_node.name = Directions.keys()[i]
			area_node.connect("input_event", Callable(self, "_on_area_click").bind(area_node.name))
			polygon_node.add_child(area_node)

			var collision = CollisionShape2D.new()
			var collision_shape = ConvexPolygonShape2D.new()

			var p_points = []
			p_points.push_back($player.position)
			p_points.push_back(POLYGON_DISTANCE * Vector2.from_angle(angles[i][0]) + $player.position)
			p_points.push_back(POLYGON_DISTANCE * Vector2.from_angle(angles[i][1]) + $player.position)

			polygon_node.polygon = p_points
			collision_shape.points = p_points
			collision.set_shape(collision_shape)
			area_node.add_child(collision)

			$areas.add_child(polygon_node)


func _on_angle_horiz_text_changed(new_text: String):
	if !new_text.is_valid_float():
		return
	angle_horizontal_axes = float(new_text)
#	result_angles_anim.Directions.EAST.angle_area_deg = clamp360(angle_horizontal_axes)
#	result_angles_anim.Directions.WEST.angle_area_deg = clamp360(angle_horizontal_axes)
	calculate_areas()


func _on_angle_vert_text_changed(new_text: String):
	if !new_text.is_valid_float():
		return
	angle_vertical_axes = float(new_text)
#	result_angles_anim.Directions.NORTH.angle_area_deg = clamp360(angle_vertical_axes)
#	result_angles_anim.Directions.SOUTH.angle_area_deg = clamp360(angle_vertical_axes)
	calculate_areas()


func _on_angle_diag_text_changed(new_text: String):
	if !new_text.is_valid_float():
		return
	angle_diagonal_axes = float(new_text)
#	result_angles_anim.Directions.NORTHEAST.angle_area_deg = clamp360(angle_diagonal_axes)
#	result_angles_anim.Directions.SOUTHEAST.angle_area_deg = clamp360(angle_diagonal_axes)
#	result_angles_anim.Directions.NORTHWEST.angle_area_deg = clamp360(angle_diagonal_axes)
#	result_angles_anim.Directions.SOUTHWEST.angle_area_deg = clamp360(angle_diagonal_axes)
	calculate_areas()


func _on_area_click(viewport: Object, event: InputEvent, shape_idx: int, area_name: String):
	if event is InputEventMouseButton and event.is_pressed():
		pass

func clamp360(angle: float):
	if angle < 0.0:
		while angle < 0.0:
			angle += 360.0
	elif angle >= 360.0:
		while angle >= 360.0:
			angle -=  360.0
	return angle
