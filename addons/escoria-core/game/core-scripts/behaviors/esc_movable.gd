## Node that performs the moving (walk, teleport, terrain scaling...) actions on
## its parent node.
extends Node
class_name ESCMovable


## Tasks carried out by this walkable node[br]
## NONE - The node is inactive[br]
## WALK - The node walks the parent somewhere[br]
## SLIDE - The node slides the parent somewhere
# TODO Currently SLIDE is no different from WALK. Consider removing.
enum MovableTask {
	NONE,
	WALK,
	SLIDE
}


## Character path through the scene as calculated by the Pathfinder
var walk_path: Array = []

## Current active walk path entry
var path_ofs: int

## The destination where the character should be moving to
var walk_destination: Vector2

## The walk context currently carried out by this movable node
var walk_context: ESCWalkContext = null

## Whether the character was moved at all
var moved: bool

## Player Direction used to reflect the movement to the new position
var last_dir: int

## Last angle calculated
var last_angle: float

## The last scaling applied to the parent
var last_scale: Vector2

## Whether the current direction animation is flipped
var is_mirrored: bool

## Shortcut variable that references the node's parent
@onready var parent = get_parent()


## Currenly running task
@onready var task = MovableTask.NONE


## Ready function. Adds the signal "arrived" to the parent node, which is emitted when the destination position was reached.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _ready() -> void:
	if not parent.has_user_signal("arrived"):
		parent.add_user_signal("arrived")


## Main processing loop[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |delta|`float`|Time that has passed since the last call to this function|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if task == MovableTask.WALK or task == MovableTask.SLIDE:
		var old_pos = parent.get_position()
		var new_pos = _calculate_movement(delta)
		if new_pos == null:
			return

		if task == MovableTask.WALK:
			# Get the angle of the object to face the position to reach.
			var angle: float = (old_pos.angle_to_point(new_pos))
			_perform_walk_orientation(angle)

		update_terrain()
	else:
		moved = false
		set_process(false)


## Calculates the next position of the object.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |delta|`float`|the time elapsed from last frame|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the new position as `Vector2`, or `null` if the movement calculation cannot proceed.
func _calculate_movement(delta: float):
	# Initialize the current pos and previous pos variables
	var pos: Vector2 = parent.get_position()
	var old_pos: Vector2 = pos

	# Get next waypoint from the walkpath array.
	var next: Vector2
	if walk_path.size() > 1:
		next = walk_path[path_ofs + 1]
	else:
		next = walk_path[path_ofs]

	# Movement speed calculation
	var a: float = pow(sin(last_angle), 2)
	var movement_speed: float = parent.speed * delta * last_scale.x * (a * last_scale.x + 1 - a) * \
			parent.terrain.player_speed_multiplier
	if walk_context.fast:
		movement_speed *= parent.terrain.player_doubleclick_speed_multiplier

	# Calculate the direction vector from current position and next waypoint
	var dir: Vector2 = (next - pos).normalized()

	# If we're close to the next waypoint (ie. distance < necessary movement
	# speed to get to this waypoint, we consider the waypoint reached
	# and pass to the next one.
	# Else, calculate the new position.
	var new_pos: Vector2
	if pos.distance_to(next) < movement_speed:
		new_pos = next
		path_ofs += 1
	else:
		new_pos = pos + dir * movement_speed * parent.v_speed_damp

	# If current waypoint id is >= the number of waypoints, were're at the
	# end of the walk: stop walking.
	if path_ofs >= walk_path.size() - 1:
		walk_stop(walk_destination)
		return

	# Update current position variable
	pos = new_pos
	parent.set_position(pos)
	return pos

## Calculates the orientation of the object while walking, to play the right animation according to this orientation.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |angle|`float`|the angle X axis and object's facing direction.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _perform_walk_orientation(angle: float):
	last_angle = angle
	last_dir = _get_dir_deg(ESCUtils.get_deg_from_rad(angle),
		parent.animations)

	var animation_player: ESCAnimationPlayer = \
			parent.get_animation_player()

	var current_animation = animation_player.get_animation()

	var animation_to_play = \
			parent.animations.directions[last_dir].animation
	if current_animation != animation_to_play and \
			animation_player.has_animation(animation_to_play):
		animation_player.play(animation_to_play)
	elif current_animation != animation_to_play and \
			not animation_player.has_animation(animation_to_play):
		current_animation = animation_to_play
		escoria.logger.warn(
			self,
			"Character %s has no animation %s\nBypassing the missing animation and movement command."
					% [parent.global_id, animation_to_play]
		)

	is_mirrored = parent.animations.directions[last_dir].mirrored


## Teleports this item to the target position.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |target|`Node`|ESCLocation or ESCItem to teleport to|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func teleport(target: Node) -> void:
	if target.has_method("get_interact_position"):
		parent.global_position = target.get_interact_position()
		escoria.logger.info(
			self,
			"Object %s is teleported to position %s."
					% [target.name, parent.global_position]
		)
	elif "position" in target:
		escoria.logger.info(
			self,
			"Object %s teleported to position %s."
					% [parent.global_id, str(target.global_position)]
		)
		parent.global_position = target.global_position
	else:
		escoria.logger.error(
			self,
			"Target %s could not be teleported. Please configure the interact position parameter or create a child ESCLocation node." % target
		)


## Teleports this item to the target position.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |target|`Vector2`|Vector2 target position to teleport to|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func teleport_to(target: Vector2) -> void:
	escoria.logger.info(
		self,
		"Object %s teleported to position %s."
				% [parent.global_id, str(target)]
	)
	parent.global_position = target


## Walk to a given position[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |pos|`Vector2`|Position to walk to|yes|[br]
## |p_walk_context|`ESCWalkContext`|Walk context to use|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func walk_to(pos: Vector2, p_walk_context: ESCWalkContext = null) -> void:
	if not parent.terrain:
		walk_stop(parent.get_global_position())
		return

	if task == MovableTask.WALK:
		if walk_context.target_object == p_walk_context.target_object \
				or walk_context.target_position \
				== p_walk_context.target_position:
			walk_context.fast = p_walk_context.fast

	walk_context = p_walk_context

	if task == MovableTask.NONE:
		task = MovableTask.WALK

	walk_path = parent.terrain.get_simple_path(parent.get_position(), pos, true)

	if walk_path.size() == 0:
		task = MovableTask.NONE
		walk_stop(parent.get_global_position())
		set_process(false)
		return
	moved = true
	walk_destination = walk_path[walk_path.size()-1]
	path_ofs = 0
	task = MovableTask.WALK
	set_process(true)


## We have finished walking. Set the idle pose and complete.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |pos|`Vector2`|Final target position|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func walk_stop(pos: Vector2) -> void:
	parent.global_position = pos
	walk_path = []

	task = MovableTask.NONE
	moved = false
	set_process(false)

	# If we're heading to an object and reached its interaction position,
	# orient towards the defined interaction direction set on the object
	# (if any), can be ESCItem or ESCLocation
	if walk_context.target_object and \
			walk_context.target_object.node.player_orients_on_arrival:

		var orientation = _get_dir_deg(walk_context.target_object.node.interaction_angle - 90,
			parent.animations)
		if orientation >= parent.animations.dir_angles.size() or orientation < 0:
			escoria.logger.warn(self, "Orientation is invalid for item '%s' (received value: %s degrees)\nPath to item: '%s'.\nDefaulting to 0 degrees."
					% [
						walk_context.target_object.global_id,
						orientation,
						walk_context.target_object.node.get_path()
					])
			orientation = 0

		last_dir = orientation
		parent.get_animation_player().play(
			parent.animations.idles[orientation].animation
		)
		is_mirrored = parent.animations.idles[orientation].mirrored
	else:
		parent.get_animation_player().play(
			parent.animations.idles[last_dir].animation
		)
		is_mirrored = parent.animations.idles[last_dir].mirrored

	update_terrain()

	if walk_context.target_object:
		escoria.logger.debug(
			self,
			"%s arrived at %s." % [
				parent.global_id,
				walk_context.target_object.global_id
			]
		)
	else:
		escoria.logger.debug(
			self,
			"%s arrived at %s." % [
				parent.global_id,
				walk_context.target_position
			]
		)
	parent.arrived.emit(walk_context)


## Update the sprite scale and lighting.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |on_event_finished_name|`Variant`|Used if this function is called from an ESC event|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func update_terrain(on_event_finished_name = null) -> void:
	if !parent.terrain or parent.terrain == null \
			or !is_instance_valid(parent.terrain):
		return
	if on_event_finished_name != null \
			and on_event_finished_name != ESCEventManager.EVENT_SETUP:
		return
	if parent.get("is_exit"):
		return
	if parent.get("dont_apply_terrain_scaling"):
		return
	if not parent.is_inside_tree():
		return

	var pos = parent.global_position
	if pos.y <= RenderingServer.CANVAS_ITEM_Z_MAX:
		parent.z_index = pos.y
	else:
		parent.z_index = RenderingServer.CANVAS_ITEM_Z_MAX

	var factor = parent.terrain.get_terrain(pos)
	var scal = parent.terrain.get_scale_range(factor)
	if scal != parent.get_scale():
		last_scale = scal
		parent.scale = last_scale

	var color = parent.terrain.get_light(pos)
	parent.modulate = color

	var sprite: Node = parent.get_sprite()

	# Do not flip the entire character, because that would conflict
	# with shadows that expect to be siblings of $texture
	#
	# - Current sprite scale is >0, meaning it's currently heading to right
	# - but calculated is_mirrored is <0, meaning it's going to head to left
	# Or, on the contrary:
	# - current sprite scale is <0, meaning it's currently heading to left
	# - but calculated is_mirrored is >0, meaning it's going to head to right
	# We're operating a 180° turn (from right to left, or from left to right)
	# So we just inverse the sprite scale.
	if is_mirrored and sprite.scale.x > 0 \
			or not is_mirrored and sprite.scale.x < 0:
		sprite.scale.x *= -1
		parent.collision.scale.x *= -1


## Get the player direction index based on degrees.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |deg|`int`|Degrees|yes|[br]
## |animations|`ESCAnimationResource`|Player animations script|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `int` value. (`int`)
func _get_dir_deg(deg: int, animations: ESCAnimationResource) -> int:
	# We turn the angle by -90° because angle_to_point gives the angle
	# against X axis, not Y
	deg = wrapi(deg + 90, 0, 360)

	var dir = -1
	var i = 0

	for direction_angle in animations.dir_angles:
		if _is_angle_in_interval(deg, direction_angle):
			dir = i
			break
		else:
			i += 1
			continue

	# It's an error to have the animations misconfigured
	if dir == -1:
		escoria.logger.error(
			self,
			"No animation has been configured for angle %s." % str(deg)
		)

	return dir


## True if given angle is inside the interval given by a starting_angle and the size.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |angle|`float`|Angle to test|yes|[br]
## |direction_angle|`ESCDirectionAngle`|ESCDirectionAngle resource, containing the starting angle, and the size of interval eg: angle_start=90, angle_size=40 corresponds to angle between 90° and 130°|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns true if given angle is inside the interval given by a starting_angle and the size. (`bool`)
func _is_angle_in_interval(
		angle: float,
		direction_angle: ESCDirectionAngle
) -> bool:
	var start_angle = direction_angle.angle_start
	var end_angle = direction_angle.angle_start + direction_angle.angle_size

	if end_angle > 360 and angle < start_angle:
		angle += 360

	return (start_angle <= angle and angle <= end_angle)


## Sets the character's facing angle and plays the corresponding idle animation.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |deg|`int`|Absolute angle in degrees (0-360) the character should face.|yes|[br]
## |wait|`float`|Optional delay in seconds before the script continues after turning.|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_angle(deg: int, wait: float = 0.0) -> void:
	if deg < 0 or deg > 360:
		escoria.logger.error(
			self,
			"Invalid degree to turn to : %s. Valid angles are between 0 and 360." % str(deg)
		)
	moved = true
	var target_dir = _get_dir_deg(deg, parent.animations)
	set_direction(target_dir, wait)


## Sets character's direction (instead of angle, see set_angle() and plays according animation.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |target_dir|`int`|int direction to set the character|yes|[br]
## |wait|`float`|float Wait this amount of seconds until continuing with turning around|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_direction(target_dir: int, wait: float = 0.0) -> void:
	if target_dir < 0 or target_dir >= parent.animations.dir_angles.size():
		escoria.logger.warn(
			self,
			"Invalid direction to turn to : %s. Valid directions are between 0 and %s. "
					% [str(target_dir), parent.animations.dir_angles.size() - 1]
			+ "Resetting target direction to 0 (up)"
		)
		target_dir = 0

	var current_dir = last_dir
	var way_to_turn = get_shortest_way_to_dir(current_dir, target_dir)

	var dir = current_dir
	while dir != target_dir:
		dir += way_to_turn
		if dir >= parent.animations.dir_angles.size():
			dir = 0
		if dir < 0:
			dir = parent.animations.dir_angles.size() - 1

		parent.get_animation_player().play(
			parent.animations.idles[dir].animation
		)
		if wait > 0.0:
			await get_tree().create_timer(wait).timeout
		is_mirrored = parent.animations.idles[dir].mirrored

	last_dir = dir

	# The character may have a state animation from before, which would be
	# resumed, so we immediately force the correct idle animation
	if parent.get_animation_player().get_animation() != \
			parent.animations.idles[last_dir].animation:
		parent.get_animation_player().play(
			parent.animations.idles[last_dir].animation
		)
	update_terrain()


## Rotates the character so it faces the supplied node and plays the matching animation.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |item|`Node`|Target node whose position the character should face.|yes|[br]
## |wait|`float`|Optional delay in seconds before the script continues after turning.|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func turn_to(item: Node, wait: float = 0.0) -> void:
	set_angle(
		wrapi(
			rad_to_deg(parent.get_position().angle_to_point(item.get_position())),
			0,
			360
		),
		wait
	)


## The angle that corresponds to the current direction of the object.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the angle that corresponds to the current direction of the object. (`int`)
func _get_angle() -> int:
	return parent.animations.dir_angles[last_dir].angle_start


## Return the shortest way to turn from a direction to another. Returned way is either: -1 (shortest way is to turn anti-clockwise) 0 (already at the right direction) 1 (clockwise).[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |current_dir|`int`|integer corresponding to the starting direction as defined in the attached ESCAnimationResource.directions.|yes|[br]
## |target_dir|`int`|integer corresponding to the target direction as defined in the attached ESCAnimationResource.directions.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `int` value. (`int`)
func get_shortest_way_to_dir(current_dir: int, target_dir: int) -> int:
	if current_dir < 0 or current_dir > parent.animations.dir_angles.size() - 1:
		escoria.logger.error(
			self,
			"Invalid direction (current_dir) %s" % str(current_dir)
		)

	if target_dir < 0 or target_dir > parent.animations.dir_angles.size() - 1:
		escoria.logger.error(
			self,
			"Invalid direction (target_dir) %s " % str(target_dir)
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
