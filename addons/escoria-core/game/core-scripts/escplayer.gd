tool
extends KinematicBody2D
class_name ESCPlayer

func get_class():
	return "ESCPlayer"

signal arrived

export var global_id : String

var params_queue : Array 
var terrain : ESCTerrain
var camera : ESCCamera

# If the terrain node type is scalenodes
var terrain_is_scalenodes : bool
var check_maps = true

var walk_path : Array = []
var walk_destination : Vector2
var walk_context
var target_object : Object = null
var moved : bool
var path_ofs : float 

export(int) var speed : int = 300
export(float) var v_speed_damp : float = 1.0
var orig_speed : float

enum PLAYER_TASKS {
	NONE,
	WALK,
	SLIDE
}
var task # type PLAYER_TASKS

# State machine defining the current interact state of the player
enum INTERACT_STATES {
	INTERACT_STARTED,	# 
	INTERACT_NONE,		#
	INTERACT_WALKING	# Player is walking
}
var interact_status		# Current interact status, type INTERACT_STATES


enum Directions {
	NORTH = 0, 		# 0
	NORTHEAST = 1, 	# 1
	EAST = 2, 		# 2
	SOUTHEAST = 3, 	# 3
	SOUTH = 4, 		# 4
	SOUTHWEST = 5, 	# 5
	WEST = 6,	 	# 6
	NORTHWEST = 7, 	# 7
	TOP = 0,
	TOP_RIGHT = 1
	RIGHT = 2,
	BOTTOM_RIGHT = 3,
	BOTTOM = 4,
	BOTTOM_LEFT = 5,
	LEFT = 6,
	TOP_LEFT = 7,
}

var last_deg : int
var last_dir : int
var last_scale : Vector2
var pose_scale : int

# Animations script (for walking, idling...)
export(Script) var animations

# AnimatedSprite node (if any)
var animation_sprite
# AnimationPlayer node (if any)
## NOT USED YET
#var animation
var collision

# Dialogs parameters
export(NodePath) var dialog_position_node
export(Color) var dialog_color = ColorN("white")

# Camera parameters
export(NodePath) var camera_position_node


func _ready():
	# Connect the player to the event_done signal, so we can react to a finished 
	# ":setup" event. In this case, we need to run update_terrain()
	escoria.esc_runner.connect("event_done", self, "update_terrain")
	
#	assert(is_angle_in_interval(0, [340,40])) # true
#	assert(is_angle_in_interval(359, [340,40])) # true
#	assert(is_angle_in_interval(1, [340,40])) # true
#	assert(!is_angle_in_interval(90, [340,40])) # false
#
#	assert(is_angle_in_interval(90, [70,40])) #true
#	assert(!is_angle_in_interval(180, [70,40])) #false
#
#	assert(is_angle_in_interval(179, [160, 40])) #true
#	assert(is_angle_in_interval(180, [160, 40])) #true
#	assert(is_angle_in_interval(181, [160, 40])) #true
#	assert(!is_angle_in_interval(0, [160, 40])) #false
#
#	assert(is_angle_in_interval(270, [250, 40])) # true
#	assert(!is_angle_in_interval(270, [70,40])) #false
	
	for n in get_children():
		if n is AnimatedSprite:
			animation_sprite = n
			
#			for sprite_child in n.get_children():
#				if sprite_child is AnimationPlayer:
#					animation = sprite_child
#					break
		
		if n is CollisionShape2D or n is CollisionPolygon2D:
			collision = n
	
	animation_sprite.connect("animation_finished", self, "anim_finished")
	
	if Engine.is_editor_hint():
		return
	
	terrain = escoria.room_terrain
	
	last_scale = scale
	
	set_process(true)


func _process(time):
	if Engine.is_editor_hint():
		return
	$debug.text = str(z_index)
	
	if task == PLAYER_TASKS.WALK or task == PLAYER_TASKS.SLIDE:
		var pos = get_position()
		var old_pos = pos
		var next
		if walk_path.size() > 1:
			next = walk_path[path_ofs + 1]
		else:
			next = walk_path[path_ofs]

		var dist = speed * time * pow(last_scale.x, 2) * terrain.player_speed_multiplier
		if walk_context and "fast" in walk_context and walk_context.fast:
			dist *= terrain.player_doubleclick_speed_multiplier
		var dir = (next - pos).normalized()

		# assume that x^2 + y^2 == 1, apply v_speed_damp the y axis
		#printt("dir before", dir)
		dir = dir * (dir.x * dir.x +  dir.y * dir.y * v_speed_damp)
		#printt("dir after", dir, dist)

		var new_pos
		if pos.distance_to(next) < dist:
			new_pos = next
			path_ofs += 1
		else:
			new_pos = pos + dir * dist

		if path_ofs >= walk_path.size() - 1:
			walk_stop(walk_destination)
			return

		pos = new_pos

		var angle = (old_pos.angle_to_point(pos))
		set_position(pos)

		if task == PLAYER_TASKS.WALK:
			last_deg = escoria.utils._get_deg_from_rad(angle)
			last_dir = _get_dir_deg(last_deg, animations)

			var current_animation = ""
			if animation_sprite != null:
				current_animation = animation_sprite.animation
#			elif animation != null:
#				current_animation = animation.current_animation
			
			if current_animation != animations.directions[last_dir][0]:
				animation_sprite.play(animations.directions[last_dir][0])
			
			pose_scale = animations.directions[last_dir][1]

		update_terrain()
	else:
		moved = false
		set_process(false)


func update_terrain(on_event_finished_name = null):
	if !terrain:
		return
	if on_event_finished_name != null and on_event_finished_name != "setup":
		return
		
	var pos = position
	z_index = pos.y if pos.y <= VisualServer.CANVAS_ITEM_Z_MAX else VisualServer.CANVAS_ITEM_Z_MAX

	var color
	if terrain_is_scalenodes:
		last_scale = terrain.get_terrain(pos)
		self.scale = last_scale
	elif check_maps:
		color = terrain.get_terrain(pos)
		var scal = terrain.get_scale_range(color.b)
		if scal != get_scale():
			last_scale = scal
			self.scale = last_scale

	# Do not flip the entire player character, because that would conflict
	# with shadows that expect to be siblings of $"sprite"
	if pose_scale == -1 and $"sprite".scale.x > 0:
		$"sprite".scale.x *= pose_scale
		collision.scale.x *= pose_scale
	elif pose_scale == 1 and $"sprite".scale.x < 0:
		$"sprite".scale.x *= -1
		collision.scale.x *= -1

#	if check_maps:
#		color = terrain.get_light(pos)
#
#	if color:
#		for s in sprites:
#			s.set_modulate(color)


"""
Sets player angle and plays according animation.
"""
func set_angle(deg):
	if deg < 0 or deg > 360:
			escoria.report_errors("escplayer.gd:set_angle()", ["Invalid degree to turn to " + str(deg)])
	moved = true
	last_deg = deg
	last_dir = _get_dir_deg(deg, animations)

	# The player may have a state animation from before, which would be
	# resumed, so we immediately force the correct idle animation
	if animation_sprite.animation != animations.idles[last_dir][0]:
		animation_sprite.play(animations.idles[last_dir][0])
	pose_scale = animations.idles[last_dir][1]
	update_terrain()

"""
Teleports the player on target position.
target can be Vector2 or Object
"""
func teleport(target, angle : Object = null) -> void:
	if typeof(target) == TYPE_VECTOR2:
		printt("Player teleported at position", target, "with angle", angle)
		position = target
	elif typeof(target) == TYPE_OBJECT:
		if target.get("interact_positions") != null:
			position = target.interact_positions.default #.global_position
		else:
			position = target.position
		printt("Player teleported at", target.name, "position", position, "with angle", angle)
	else:
		escoria.report_errors("escplayer.gd", ["target to teleport player to is null or unusable (" + target + ")"])

# PUBLIC FUNCTION
func walk_to(pos : Vector2, p_walk_context = null):
	if not terrain:
		return walk_stop(get_position())

	if interact_status == INTERACT_STATES.INTERACT_WALKING:
		return
	if interact_status == INTERACT_STATES.INTERACT_STARTED:
		interact_status = INTERACT_STATES.INTERACT_WALKING
	walk_path = terrain.get_terrain_path(get_position(), pos)
	walk_context = p_walk_context
	if walk_path.size() == 0:
		task = PLAYER_TASKS.NONE
		walk_stop(get_position())
		set_process(false)
		return
	moved = true
	walk_destination = walk_path[walk_path.size()-1]
	if terrain.is_solid(pos):
		walk_destination = walk_path[walk_path.size()-1]
	path_ofs = 0.0
	task = PLAYER_TASKS.WALK
	set_process(true)

# PRIVATE FUNCTION
func walk(target_pos, p_speed, context = null):
	if p_speed:
		orig_speed = speed
		speed = p_speed
	walk_to(target_pos, context)

# PRIVATE FUNCTION
func walk_stop(pos):
	position = pos
	interact_status = INTERACT_STATES.INTERACT_NONE
	walk_path = []

	if orig_speed:
		speed = orig_speed
		orig_speed = 0.0

	task = PLAYER_TASKS.NONE
	moved = false
	set_process(false)
	if params_queue != null && !params_queue.empty():
		if animations.dir_angles.size() > 0:
			if params_queue[0].interact_angle == -1:
				escoria.tools.resolve_angle_to(params_queue[0])
			else:
				last_dir = _get_dir_deg(params_queue[0].interact_angle, animations)
			animation_sprite.play(animations.idles[last_dir][0])
			pose_scale = animations.idles[last_dir][1]
			update_terrain()
		else:
			animation_sprite.play(animations.idles[last_dir][0])
			pose_scale = animations.idles[last_dir][1]
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "interact", params_queue)
		# Clear params queue to prevent the same action from being triggered again
		params_queue = []
	else:
		
		# If we're heading to an object and reached its interaction position,
		# orient towards the defined interaction direction set on the object (if any)
		if walk_context.has("target_object") and walk_context.target_object.player_orients_on_arrival \
				and escoria.esc_runner.get_interactive(walk_context.target_object.global_id):
			var orientation = walk_context["target_object"].interaction_direction
			animation_sprite.play(animations.idles[orientation][0])
			pose_scale = animations.idles[orientation][1]
		else:
			animation_sprite.play(animations.idles[last_dir][0])
			pose_scale = animations.idles[last_dir][1]
	update_terrain()
	
	if walk_context != null:
		escoria.esc_level_runner.finished(walk_context)
		walk_context = null
	emit_signal("arrived")


func anim_finished():
	pass


func get_camera_pos():
	if camera_position_node and get_node(camera_position_node):
		return get_node(camera_position_node).global_position
	return global_position


func get_animations_list() -> PoolStringArray:
	return animation_sprite.get_sprite_frames().get_animation_names()


func _get_dir(angle : float, animations) -> int: 
	var deg = escoria.utils._get_deg_from_rad(angle)
	return _get_dir_deg(deg, animations)


func _get_dir_deg(deg : int, animations) -> int:
	# We turn the angle by -90° because angle_to_point gives the angle against X axis, not Y
	deg = wrapi(deg - 90, 0, 360)
	var dir = -1
	var i = 0
	
	for arr_angle_zone in animations.dir_angles:
		if is_angle_in_interval(deg, arr_angle_zone):
			dir = i
			break
		else:
			i += 1
			continue

	# It's an error to have the animations misconfigured
	if dir == -1:
		escoria.report_errors("escplayer.gd:_get_dir_deg()", ["No direction found for " + str(deg)])
	
	return dir


# Returns true if given angle is inside the interval given by a starting_angle and the size.
# @param angle : Angle to test
# @param: interval : Array of size 2, containing the starting angle, and the size of interval
# eg: [90, 40] corresponds to angle between 90° and 130°
func is_angle_in_interval(angle: float, interval : Array) -> bool:
	angle = wrapi(angle, 0, 360)
	if angle == 0:
		angle = 360
	var start_angle = wrapi(interval[0], 0, 360)
	var angle_area = interval[1]
	var end_angle = wrapi(interval[0] + angle_area, 0, 360) 
	
	if (angle >= 270 and angle <= 360) or (angle >= 0 and angle <= 90):
		if wrapi(angle+180, 0, 360) > wrapi(interval[0]+ 180, 0, 360)  \
			&& wrapi(angle+180, 0, 360) <= wrapi(interval[0] + angle_area + 180, 0, 360):
			return true
	else:
		if wrapi(angle, 0, 360) > start_angle && wrapi(angle, 0, 360) <= end_angle:
			return true
	
	return false
	
	
