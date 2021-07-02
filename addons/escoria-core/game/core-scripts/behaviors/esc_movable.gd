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

# Angle degrees to the last position (TODO is that correct?)
var last_deg: int

# Direction of the last position (TODO is that correct?)
var last_dir: int

# Scale of the last position (TODO is that correct?)
var last_scale: Vector2

# TODO Isn't this actually the flip state of the current animation?
var pose_scale: int


var _orig_speed: float = 0.0


# Shortcut variable that references the node's parent
onready var parent = get_parent()

# If character misses an animation, bypass it and proceed.
onready var bypass_missing_animation = false


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
	
	if task == MovableTask.WALK or \
				task == MovableTask.SLIDE:
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

		# TODO comment what this is all about
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
#			elif animation != null:
#				current_animation = animation.current_animation
			
			# FIXME This is obviously wrong as bypass_missing_animation is
			# always false
			bypass_missing_animation = false
			if !bypass_missing_animation:
				var animation_to_play = \
						parent.animations.directions[last_dir][0]
				if current_animation != animation_to_play:
					if parent.animation_sprite.frames.has_animation(
						animation_to_play
					):
						parent.animation_sprite.play(animation_to_play)
					else:
						bypass_missing_animation = true
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
			
			pose_scale = parent.animations.directions[last_dir][1]

		update_terrain()
	else:
		moved = false
		set_process(false)


# Teleports this item to the target position.
# TODO angle is only used for logging and has no further use, so it probably
# can be removed
#
# #### Parameters
#
# - target: Position2d or ESCItem to teleport to
func teleport(target: Node, angle: Object = null) -> void:
	if target is Position2D:
		escoria.logger.info(
			"Object %s teleported at position %s with angle" %
			[parent.global_id, str(target.position)],
			[angle]
		)
		parent.position = target.position
	elif typeof(target) == TYPE_OBJECT:
		# FIXME this is better written as target is ESCItem if that's
		# the only case here
#		if target.get("interact_positions") != null:
#			parent.position = target.interact_positions.default
#		else:
#			parent.position = target.position
		parent.position = target.get_interact_position()
		escoria.logger.info("Object " + target.name + " teleported at position " 
			+ str(parent.position) + " with angle ", str(angle))
	else:
		escoria.logger.report_errors("escitem.gd:teleport()",
		["Target to teleport to is null or unusable (" + str(target) + ")"])


# Teleports this item to the target position.
# TODO angle is only used for logging and has no further use, so it probably
# can be removed
#
# #### Parameters
#
# - target: Vector2 target position to teleport to 
func teleport_to(target: Vector2, angle: Object = null) -> void:
	if typeof(target) == TYPE_VECTOR2 :
		escoria.logger.info(
			"Object %s teleported at position %s with angle" %
			[parent.global_id, str(target)],
			[angle]
		)
		parent.position = target
	else:
		escoria.logger.report_errors("escitem.gd:teleport_to()",
		["Target to teleport to is null or unusable (" + str(target) + ")"])


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


# FIXME this function doesn't seem to be used anywhere
func walk(target_pos, p_speed, context = null) -> void:
	if p_speed:
		_orig_speed = parent.speed
		parent.speed = p_speed
	walk_to(target_pos, context)


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
			parent.animations.idles[orientation][0]
		)
		pose_scale = parent.animations.idles[orientation][1]
	else:
		parent.animation_sprite.play(parent.animations.idles[last_dir][0])
		pose_scale = parent.animations.idles[last_dir][1]
	
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
	# TODO Make the character sprite not rely on the node name
	if pose_scale == -1 and parent.get_node("sprite").scale.x > 0:
		parent.get_node("sprite").scale.x *= pose_scale
		parent.collision.scale.x *= pose_scale
	elif pose_scale == 1 and parent.get_node("sprite").scale.x < 0:
		parent.get_node("sprite").scale.x *= -1
		parent.collision.scale.x *= -1


# Get the player direction index based on rotation angles
#
# FIXME: This function doesn't seem to be used anymore
# #### Parameters
#
# - angle: The rotation angle
# - animations: The list of character animations
func _get_dir(angle: float, animations) -> int:
	var deg = escoria.utils.get_deg_from_rad(angle)
	return _get_dir_deg(deg, animations)


# Get the player direction index based on degrees
#
# #### Parameters
#
# - deg: Degrees
# - animations: Player animations script
func _get_dir_deg(deg: int, animations: Script) -> int:
	# We turn the angle by -90° because angle_to_point gives the angle
	# against X axis, not Y
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
		escoria.logger.report_errors(
			"escitem.gd:_get_dir_deg()",
			["No direction found for " + str(deg)]
		)
	
	return dir


# Returns true if given angle is inside the interval given by a starting_angle
# and the size.
# TODO Refactor to make this stuff understandable :D
#
# #### Parameters
#
# - angle: Angle to test
# - interval: Array of size 2, containing the starting angle, and the size of
#   interval
#   eg: [90, 40] corresponds to angle between 90° and 130°
func is_angle_in_interval(angle: float, interval: Array) -> bool:
	angle = wrapi(angle, 0, 360)
	if angle == 0:
		angle = 360
	var start_angle = wrapi(interval[0], 0, 360)
	var angle_area = interval[1]
	var end_angle = wrapi(interval[0] + angle_area, 0, 360) 
	
	if ((angle >= 270 and angle <= 360) \
			or (angle >= 0 and angle <= 90)) \
			and wrapi(angle + 180, 0, 360) > wrapi(interval[0] + 180, 0, 360) \
			and wrapi(angle + 180, 0, 360) <= wrapi(
				interval[0] + angle_area + 180, 0, 360
			):
		return true
	elif wrapi(angle, 0, 360) > start_angle \
			and wrapi(angle, 0, 360) <= end_angle:
		return true
	
	return false

# Sets character's angle and plays according animation.
#
# TODO: depending on current angle and current angle, the character may
# directly turn around with no "progression". We may enhance this by
# calculating successive directions to turn the character to, so that he
# doesn't switch to opposite direction too fast.
# For example, if character looks WEST and set_angle(EAST) is called, we may
# want the character to first turn SOUTHWEST, then SOUTH, then SOUTHEAST and
# finally EAST, all more or less fast.
# Whatever the implementation, this should be activated using "parameter
# "immediate" set to false.
#
# #### Parameters
#
# - deg int angle to set the character
# - immediate bool (currently unused, see TODO below)
#	If true, direction is switched immediately. Else, successive animations are
#	used so that the character turns to target angle.
func set_angle(deg: int, immediate = true) -> void:
	if deg < 0 or deg > 360:
		escoria.logger.report_errors(
			"movable.gd:set_angle()",
			["Invalid degree to turn to " + str(deg)]
		)
	moved = true
	last_deg = deg
	last_dir = _get_dir_deg(deg, parent.animations)

	# The character may have a state animation from before, which would be
	# resumed, so we immediately force the correct idle animation
	if parent.animation_sprite.animation != \
			parent.animations.idles[last_dir][0]:
		parent.animation_sprite.play(parent.animations.idles[last_dir][0])
	pose_scale = parent.animations.idles[last_dir][1]
	update_terrain()

# Returns the angle that corresponds to the current direction of the object.
func _get_angle() -> int:
	return parent.animations.dir_angles[last_dir][0]
	
