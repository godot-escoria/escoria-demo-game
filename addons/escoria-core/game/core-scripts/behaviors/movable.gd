tool
extends Node
class_name Movable

"""
This class performs the moving (walk, teleport, terrain scaling...) actions on 
the parent node.
"""


onready var parent = get_parent()

# If character misses an animation, bypass it and proceed.
onready var bypass_missing_animation = false

var walk_path : Array = []
var walk_destination : Vector2
var walk_context
var moved : bool
var path_ofs : float 

var last_deg : int
var last_dir : int
var last_scale : Vector2
var pose_scale : int



func _ready():
	parent.add_user_signal("arrived")

func _process(time):
	if Engine.is_editor_hint():
		return
	
	if parent.task == parent.PLAYER_TASKS.WALK or parent.task == parent.PLAYER_TASKS.SLIDE:
		var pos = parent.get_position()
		var old_pos = pos
		var next
		if walk_path.size() > 1:
			next = walk_path[path_ofs + 1]
		else:
			next = walk_path[path_ofs]

		var dist = parent.speed * time * pow(last_scale.x, 2) * \
			parent.terrain.player_speed_multiplier
		if walk_context and "fast" in walk_context and walk_context.fast:
			dist *= parent.terrain.player_doubleclick_speed_multiplier
		var dir = (next - pos).normalized()

		# assume that x^2 + y^2 == 1, apply v_speed_damp the y axis
		#printt("dir before", dir)
		dir = dir * (dir.x * dir.x +  dir.y * dir.y * parent.v_speed_damp)
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
		parent.set_position(pos)

		if parent.task == parent.PLAYER_TASKS.WALK:
			last_deg = escoria.utils._get_deg_from_rad(angle)
			last_dir = _get_dir_deg(last_deg, parent.animations)

			var current_animation = ""
			if parent.animation_sprite != null:
				current_animation = parent.animation_sprite.animation
#			elif animation != null:
#				current_animation = animation.current_animation
			
			bypass_missing_animation = false
			if !bypass_missing_animation:
				var animation_to_play = parent.animations.directions[last_dir][0]
				if current_animation != animation_to_play:
					if parent.animation_sprite.frames.has_animation(animation_to_play):
						parent.animation_sprite.play(animation_to_play)
					else:
						bypass_missing_animation = true
						current_animation = animation_to_play
						escoria.logger.report_warnings("movable.gd:_process()", 
							["Character " + parent.global_id + " has no animation " + animation_to_play,
							"Bypassing missing animation and proceed movement."], true)
			
			pose_scale = parent.animations.directions[last_dir][1]

		update_terrain()
	else:
		moved = false
		set_process(false)


func teleport(target, angle : Object = null) -> void:
	"""
	Teleports the item on target position.
	target can be Vector2 or Object
	"""
	if typeof(target) == TYPE_VECTOR2 :
		escoria.logger.info("Object " + parent.global_id + " teleported at position " + 
			str(target) + " with angle", [angle])
		parent.position = target
	elif target is Position2D:
		escoria.logger.info("Object " + parent.global_id + " teleported at position " + 
			str(target.position) + " with angle", [angle])
		parent.position = target.position
	elif typeof(target) == TYPE_OBJECT:
#		if target.get("interact_positions") != null:
#			parent.position = target.interact_positions.default #.global_position
#		else:
#			parent.position = target.position
		parent.position = target.get_interact_position()
		escoria.logger.info("Object " + target.name + " teleported at position " 
			+ str(parent.position) + " with angle ", str(angle))
	else:
		escoria.logger.report_errors("escitem.gd:teleport()", ["Target to teleport to is null or unusable (" + target + ")"])

# PUBLIC FUNCTION
func walk_to(pos : Vector2, p_walk_context = null):
	if not parent.terrain:
		return walk_stop(parent.get_position())
		
	if parent.task == parent.PLAYER_TASKS.WALK:
		if walk_context.has("target_object") and p_walk_context.has("target_object"):
			if walk_context["target_object"] == p_walk_context["target_object"]:
				walk_context["fast"] = p_walk_context["fast"]
				return true
		elif walk_context.has("target") and p_walk_context.has("target"):
			if walk_context["target"] == p_walk_context["target"]:
				walk_context["fast"] = p_walk_context["fast"]
				return true
		else:
			pass
	if parent.task == parent.PLAYER_TASKS.NONE:
		parent.task = parent.PLAYER_TASKS.WALK
	walk_path = parent.terrain.get_terrain_path(parent.get_position(), pos)
	walk_context = p_walk_context
	if walk_path.size() == 0:
		parent.task = parent.PLAYER_TASKS.NONE
		walk_stop(parent.get_position())
		set_process(false)
		return
	moved = true
	walk_destination = walk_path[walk_path.size()-1]
	if parent.terrain.is_solid(pos):
		walk_destination = walk_path[walk_path.size()-1]
	path_ofs = 0.0
	parent.task = parent.PLAYER_TASKS.WALK
	set_process(true)

# PRIVATE FUNCTION
func walk(target_pos, p_speed, context = null):
	if p_speed:
		parent.orig_speed = parent.speed
		parent.speed = p_speed
	walk_to(target_pos, context)

# PRIVATE FUNCTION
func walk_stop(pos):
	parent.position = pos
#	parent.interact_status = parent.INTERACT_STATES.INTERACT_NONE
	walk_path = []

	if parent.orig_speed:
		parent.speed = parent.orig_speed
		parent.orig_speed = 0.0

	parent.task = parent.PLAYER_TASKS.NONE
	moved = false
	set_process(false)
	if parent.params_queue != null && !parent.params_queue.empty():
		if parent.animations.dir_angles.size() > 0:
			if parent.arams_queue[0].interact_angle == -1:
				escoria.tools.resolve_angle_to(parent.params_queue[0])
			else:
				last_dir = _get_dir_deg(parent.params_queue[0].interact_angle, parent.animations)
			parent.animation_sprite.play(parent.animations.idles[last_dir][0])
			pose_scale = parent.animations.idles[last_dir][1]
			update_terrain()
		else:
			parent.animation_sprite.play(parent.animations.idles[last_dir][0])
			pose_scale = parent.animations.idles[last_dir][1]
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "interact", parent.params_queue)
		# Clear params queue to prevent the same action from being triggered again
		parent.params_queue = []
	else:
		
		# If we're heading to an object and reached its interaction position,
		# orient towards the defined interaction direction set on the object (if any)
		if walk_context.has("target_object") \
				and walk_context.target_object.player_orients_on_arrival \
				and escoria.esc_runner.get_interactive(walk_context.target_object.global_id):
			var orientation = walk_context["target_object"].interaction_direction
			last_dir = orientation
			parent.animation_sprite.play(parent.animations.idles[orientation][0])
			pose_scale = parent.animations.idles[orientation][1]
			
		else:
			parent.animation_sprite.play(parent.animations.idles[last_dir][0])
			pose_scale = parent.animations.idles[last_dir][1]
	update_terrain()
	
	if walk_context != null:
		escoria.esc_level_runner.finished(walk_context)
		escoria.esc_level_runner.finished()
#		walk_context = null
	
	yield(parent.animation_sprite, "animation_finished")
	escoria.logger.info(parent.global_id + " arrived at " + str(walk_context))
	parent.emit_signal("arrived", walk_context)


func update_terrain(on_event_finished_name = null):
	if !parent.terrain or parent.terrain == null or !is_instance_valid(parent.terrain):
		return
	if on_event_finished_name != null and on_event_finished_name != "setup":
		return
	if parent.get("is_exit"):
		return
	if parent.get("dont_apply_terrain_scaling"):
		return
		
	var pos = parent.position
	parent.z_index = pos.y if pos.y <= VisualServer.CANVAS_ITEM_Z_MAX else VisualServer.CANVAS_ITEM_Z_MAX

	var color
	if parent.terrain_is_scalenodes:
		last_scale = parent.terrain.get_terrain(pos)
		parent.scale = last_scale
	elif parent.check_maps:
		color = parent.terrain.get_terrain(pos)
		var scal = parent.terrain.get_scale_range(color.b)
		if scal != parent.get_scale():
			last_scale = scal
			parent.scale = last_scale

	# Do not flip the entire character, because that would conflict
	# with shadows that expect to be siblings of $texture
	if pose_scale == -1 and parent.get_node("sprite").scale.x > 0:
		parent.get_node("sprite").scale.x *= pose_scale
		parent.collision.scale.x *= pose_scale
	elif pose_scale == 1 and parent.get_node("sprite").scale.x < 0:
		parent.get_node("sprite").scale.x *= -1
		parent.collision.scale.x *= -1

#	if parent.check_maps:
#		color = parent.terrain.get_light(pos)
#
#	if color:
#		for s in sprites:
#			s.set_modulate(color)

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
		escoria.logger.report_errors("escitem.gd:_get_dir_deg()", ["No direction found for " + str(deg)])
	
	return dir

"""
Returns true if given angle is inside the interval given by a starting_angle and the size.
@param angle : Angle to test
@param: interval : Array of size 2, containing the starting angle, and the size of interval
 eg: [90, 40] corresponds to angle between 90° and 130°
"""
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

"""
Sets character's angle and plays according animation.
- deg int angle to set the character 
- immediate bool (currently unused, see TODO below)
	If true, direction is switched immediately. Else, successive animations are
	used so that the character turns to target angle. 

TODO: depending on current angle and current angle, the character may directly turn around
with no "progression". We may enhance this by calculating successive directions to turn the
character to, so that he doesn't switch to opposite direction too fast.
For example, if character looks WEST and set_angle(EAST) is called, we may want the character
to first turn SOUTHWEST, then SOUTH, then SOUTHEAST and finally EAST, all more or less fast. 
Whatever the implementation, this should be activated using "parameter "immediate" set to false.
"""
func set_angle(deg : int, immediate = true):
	if deg < 0 or deg > 360:
		escoria.logger.report_errors("movable.gd:set_angle()", ["Invalid degree to turn to " + str(deg)])
	moved = true
	last_deg = deg
	last_dir = _get_dir_deg(deg, parent.animations)

	# The character may have a state animation from before, which would be
	# resumed, so we immediately force the correct idle animation
	if parent.animation_sprite.animation != parent.animations.idles[last_dir][0]:
		parent.animation_sprite.play(parent.animations.idles[last_dir][0])
	pose_scale = parent.animations.idles[last_dir][1]
	update_terrain()
