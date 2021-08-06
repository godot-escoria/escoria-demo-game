# Node that performs the moving (walk, teleport, terrain scaling...) actions on
# its parent node.
tool
extends Node
class_name ESCMovable


# Tasks carried out by this walkable node
# NONE - The node is inactive
# WALK - The node walks the parent somewhere
# SLIDE - The node slides the parent somewhere
enum MovableTask {
	NONE,
	WALK,
	SLIDE
}


# Character path through the scene as calculated by the Pathfinder
var walk_path: Array = []

# Current active walk path entry
var path_ofs: int

# The destination where the character should be moving to
var walk_destination: Vector2

# The walk context currently carried out by this movable node
var walk_context: ESCWalkContext = null

# Wether the character was moved at all
var moved: bool

# Angle degrees from the last position to the next
var last_deg: int

# Player Direction used to reflect the movement to the new position
var last_dir: int

# The last scaling applied to the parent
var last_scale: Vector2

# Wether the current direction animation is flipped
var pose_scale: int


var _orig_speed: float = 0.0


# Shortcut variable that references the node's parent
onready var parent = get_parent()


# Currenly running task
onready var task = MovableTask.NONE


# Add the signal "arrived" to the parent node, which is emitted when
# the destination position was reached
func _ready() -> void:
	parent.add_user_signal("arrived")
	

# Main processing loop
#
# #### Parameters
#
# - delta: Time that has passed since the last call to this function
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if task == MovableTask.WALK or task == MovableTask.SLIDE:
		var pos = parent.get_position()
		var old_pos = pos
		var next
		if walk_path.size() > 1:
			next = walk_path[path_ofs + 1]
		else:
			next = walk_path[path_ofs]

		var dist = parent.speed * delta * pow(last_scale.x, 2) * \
			parent.terrain.player_speed_multiplier
		if walk_context.fast:
			dist *= parent.terrain.player_doubleclick_speed_multiplier
		var dir = (next - pos).normalized()

		dir = dir * (dir.x * dir.x +  dir.y * dir.y * parent.v_speed_damp)

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

		if task == MovableTask.WALK:
			last_deg = escoria.utils.get_deg_from_rad(angle)
			last_dir = _get_dir_deg(last_deg, parent.animations)

			var current_animation = ""
			if parent.animation_sprite != null:
				current_animation = parent.animation_sprite.animation
			
			var animation_to_play = \
					parent.animations.directions[last_dir].animation
			if current_animation != animation_to_play:
				if parent.animation_sprite.frames.has_animation(
					animation_to_play
				):
					parent.animation_sprite.play(animation_to_play)
				else:
					current_animation = animation_to_play
					escoria.logger.report_warnings(
						"movable.gd:_process()",
						[
							"Character %s has no animation %s "
							% [parent.global_id, animation_to_play],
							"Bypassing missing animation and " +
							"proceed movement."
						],
						true
					)
			
			pose_scale = -1 if parent.animations.directions[last_dir].mirrored \
				else 1

		update_terrain()
	else:
		moved = false
		set_process(false)


# Teleports this item to the target position.
#
# #### Parameters
#
# - target: Position2d or ESCItem to teleport to
func teleport(target: Node) -> void:
	if target.has_method("get_interact_position"):
		parent.position = target.get_interact_position()
		escoria.logger.info(
			"Object %s is teleported at position %s" % [
				target.name,
				parent.position
			] 
		)
	elif "position" in target:
		escoria.logger.info(
			"Object %s teleported at position %s" %
			[parent.global_id, str(target.position)]
		)
		parent.position = target.position
	else:
		escoria.logger.report_errors(
			"ESCMovable#teleport()",
			["Couldn't understand how to manage teleport Target %s" % target]
		)


# Teleports this item to the target position.
#
# #### Parameters
#
# - target: Vector2 target position to teleport to 
func teleport_to(target: Vector2) -> void:
	escoria.logger.info(
		"Object %s teleported to position %s" %
		[parent.global_id, str(target)]
	)
	parent.position = target


# Walk to a given position
#
# #### Parameters
#
# - pos: Position to walk to
# - p_walk_context: Walk context to use
func walk_to(pos: Vector2, p_walk_context: ESCWalkContext = null) -> void:
	if not parent.terrain:
		walk_stop(parent.get_position())
		return
		
	if task == MovableTask.WALK:
		if walk_context.target_object == p_walk_context.target_object \
		or walk_context.target_position == p_walk_context.target_position:
			walk_context.fast = p_walk_context.fast
	
	walk_context = p_walk_context
	
	if task == MovableTask.NONE:
		task = MovableTask.WALK
	
	walk_path = parent.terrain.get_simple_path(parent.get_position(), pos, true)
	
	if walk_path.size() == 0:
		task = MovableTask.NONE
		walk_stop(parent.get_position())
		set_process(false)
		return
	moved = true
	walk_destination = walk_path[walk_path.size()-1]
	path_ofs = 0
	task = MovableTask.WALK
	set_process(true)


# We have finished walking. Set the idle pose and complete
#
# #### Parameters
#
# - pos: Final target position
func walk_stop(pos: Vector2) -> void:
	parent.position = pos
#	parent.interact_status = parent.INTERACT_STATES.INTERACT_NONE
	walk_path = []

	if _orig_speed > 0:
		parent.speed = _orig_speed
		_orig_speed = 0.0

	task = MovableTask.NONE
	moved = false
	set_process(false)
	
	# If we're heading to an object and reached its interaction position,
	# orient towards the defined interaction direction set on the object
	# (if any)
	if walk_context.target_object and \
			walk_context.target_object.node.player_orients_on_arrival and \
			walk_context.target_object.interactive:
		var orientation = walk_context.target_object.node.interaction_direction
		last_dir = orientation
		parent.animation_sprite.play(
			parent.animations.idles[orientation].animation
		)
		pose_scale = -1 if parent.animations.idles[orientation].mirrored else 1
	else:
		parent.animation_sprite.play(
			parent.animations.idles[last_dir].animation
		)
		pose_scale = -1 if parent.animations.idles[last_dir].mirrored else 1
	
	update_terrain()

	yield(parent.animation_sprite, "animation_finished")
	if walk_context.target_object:
		escoria.logger.debug(
			"%s arrived at %s" % [
				parent.global_id,
				walk_context.target_object.global_id
			]
		)
	else:
		escoria.logger.debug(
			"%s arrived at %s" % [
				parent.global_id,
				walk_context.target_position
			]
		)
	parent.emit_signal("arrived", walk_context)


# Update the sprite scale and lighting
#
# #### Parameters
#
# - on_event_finished_name: Used if this function is called from an ESC event
func update_terrain(on_event_finished_name = null) -> void:
	if !parent.terrain or parent.terrain == null \
			or !is_instance_valid(parent.terrain):
		return
	if on_event_finished_name != null and on_event_finished_name != "setup":
		return
	if parent.get("is_exit"):
		return
	if parent.get("dont_apply_terrain_scaling"):
		return
		
	var pos = parent.position
	if pos.y <= VisualServer.CANVAS_ITEM_Z_MAX:
		parent.z_index = pos.y
	else:
		parent.z_index = VisualServer.CANVAS_ITEM_Z_MAX

	var factor = parent.terrain.get_terrain(pos)
	var scal = parent.terrain.get_scale_range(factor)
	if scal != parent.get_scale():
		last_scale = scal
		parent.scale = last_scale
		
	var color = parent.terrain.get_light(pos)
	parent.modulate = color

	# Do not flip the entire character, because that would conflict
	# with shadows that expect to be siblings of $texture
	if pose_scale == -1 and parent.get_node("sprite").scale.x > 0:
		parent.get_node("sprite").scale.x *= pose_scale
		parent.collision.scale.x *= pose_scale
	elif pose_scale == 1 and parent.get_node("sprite").scale.x < 0:
		parent.get_node("sprite").scale.x *= -1
		parent.collision.scale.x *= -1


# Get the player direction index based on degrees
#
# #### Parameters
#
# - deg: Degrees
# - animations: Player animations script
func _get_dir_deg(deg: int, animations: ESCAnimationResource) -> int:
	# We turn the angle by -90° because angle_to_point gives the angle
	# against X axis, not Y
	deg = wrapi(deg - 90, 0, 360)
	var dir = -1
	var i = 0
	
	for direction_angle in animations.dir_angles:
		if is_angle_in_interval(deg, direction_angle):
			dir = i
			break
		else:
			i += 1
			continue

	# It's an error to have the animations misconfigured
	if dir == -1:
		escoria.logger.report_errors(
			"escitem.gd:_get_dir_deg()",
			["No direction found for " + str(deg)]
		)
	
	return dir


# Returns true if given angle is inside the interval given by a starting_angle
# and the size.
#
# #### Parameters
#
# - angle: Angle to test
# - direction_angle: ESCDirectionAngle resource, containing the starting angle,
#  and the size of interval 
# eg: angle_start=90, angle_size=40 corresponds to angle between 90° and 130°
func is_angle_in_interval(
		angle: float, 
		direction_angle: ESCDirectionAngle
) -> bool:
	angle = wrapi(angle, 0, 360)
	if angle == 0:
		angle = 360
	var start_angle = wrapi(direction_angle.angle_start, 0, 360)
	var angle_area = direction_angle.angle_size
	var end_angle = wrapi(direction_angle.angle_start + angle_area, 0, 360) 
	
	if ((angle >= 270 and angle <= 360) \
			or (angle >= 0 and angle <= 90)) \
			and wrapi(angle + 180, 0, 360) > wrapi(direction_angle.angle_start 
				+ 180, 0, 360) \
			and wrapi(angle + 180, 0, 360) <= wrapi(
				direction_angle.angle_start + angle_area + 180, 0, 360
			):
		return true
	elif wrapi(angle, 0, 360) > start_angle \
			and wrapi(angle, 0, 360) <= end_angle:
		return true
	
	return false

# Sets character's angle and plays according animation.
#
# #### Parameters
#
# - deg int angle to set the character
# - immediate
#	If true, direction is switched immediately. Else, successive 
#	animations are used so that the character turns to target angle.
func set_angle(deg: int, immediate = true) -> void:
	if deg < 0 or deg > 360:
		escoria.logger.report_errors(
			"movable.gd:set_angle()",
			["Invalid degree to turn to " + str(deg)]
		)
	moved = true
	
	if immediate:
		last_deg = deg
		last_dir = _get_dir_deg(deg, parent.animations)

		# The character may have a state animation from before, which would be
		# resumed, so we immediately force the correct idle animation
		if parent.animation_sprite.animation != \
				parent.animations.idles[last_dir].animation:
			parent.animation_sprite.play(
				parent.animations.idles[last_dir].animation
			)
		pose_scale = -1 if parent.animations.idles[last_dir].mirrored else 1
	else:
		var current_dir = last_dir
		last_deg = deg
		var target_dir = _get_dir_deg(deg, parent.animations)
		
		var way_to_turn = get_shortest_way_to_dir(current_dir, target_dir)
	
		var dir = current_dir
		while dir != target_dir:
			dir += way_to_turn
			if dir >= parent.animations.dir_angles.size():
				dir = 0
			if dir < 0:
				dir = parent.animations.dir_angles.size() - 1
			
			parent.animation_sprite.play(
				parent.animations.idles[dir].animation
			)
			yield(parent.animation_sprite, "animation_finished")
			pose_scale = -1 if parent.animations.idles[dir].mirrored else 1
			
	update_terrain()


# Returns the angle that corresponds to the current direction of the object.
func _get_angle() -> int:
	return parent.animations.dir_angles[last_dir].animation


# Return the shortest way to turn from a direction to another. Returned way is
# either: 
# -1 (shortest way is to turn anti-clockwise) 
# 0 (already at the right direction)
# 1 (clockwise).
#
# ####Parameters
# - current_dir: integer corresponding to the starting direction as defined in
# the attached ESCAnimationResource.directions.
# - target_dir: integer corresponding to the target direction as defined in
# the attached ESCAnimationResource.directions.
#
# *Returns*
# Integer: -1 (anti-clockwise), 1 (clockwise) or 0 (no movement needed).
func get_shortest_way_to_dir(current_dir: int, target_dir: int) -> int:
	if current_dir < 0 or current_dir > parent.animations.dir_angles.size() - 1:
		escoria.logger.report_errors(
			"esc_movable.gd:get_shortest_way_to_dir()",
			["Invalid direction (current_dir) %s" % str(current_dir)]
		)
	
	if target_dir < 0 or target_dir > parent.animations.dir_angles.size() - 1:
		escoria.logger.report_errors(
			"esc_movable.gd:get_shortest_way_to_dir()",
			["Invalid direction (target_dir) %s " % str(target_dir)]
		)
	
	if current_dir == target_dir:
		return 0
	
	var internal = false
	if max(current_dir, target_dir) - min(current_dir, target_dir) \
			< parent.animations.dir_angles.size() / 2:
		internal = true
	else:
		internal = false
	
	if internal and current_dir < target_dir or \
			(not internal and current_dir > target_dir):
		return 1
	else:
		return -1
