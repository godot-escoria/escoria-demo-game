tool
extends KinematicBody2D
class_name ESCPlayer

func get_class():
	return "ESCPlayer"

"""
TODO
- Currently the sprite node needs to be named "sprite". This is bad.
- Animation management doesn't allow using AnimationPlayer yet. Need to find 
	the best solution to manage both AnimatedSprite and AnimationPlayer.
"""

var Movable : Node
var MovableScript = load("res://addons/escoria-core/game/core-scripts/behaviors/movable.gd")

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
	# Adds movable behavior
	Movable = Node.new()
	Movable.set_script(MovableScript)
	add_child(Movable)
	
	
	# Connect the player to the event_done signal, so we can react to a finished 
	# ":setup" event. In this case, we need to run update_terrain()
	escoria.esc_runner.connect("event_done", Movable, "update_terrain")
	
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
	
#	if task == PLAYER_TASKS.WALK or task == PLAYER_TASKS.SLIDE:
#		var pos = get_position()
#		var old_pos = pos
#		var next
#		if walk_path.size() > 1:
#			next = walk_path[path_ofs + 1]
#		else:
#			next = walk_path[path_ofs]
#
#		var dist = speed * time * pow(last_scale.x, 2) * terrain.player_speed_multiplier
#		if walk_context and "fast" in walk_context and walk_context.fast:
#			dist *= terrain.player_doubleclick_speed_multiplier
#		var dir = (next - pos).normalized()
#
#		# assume that x^2 + y^2 == 1, apply v_speed_damp the y axis
#		#printt("dir before", dir)
#		dir = dir * (dir.x * dir.x +  dir.y * dir.y * v_speed_damp)
#		#printt("dir after", dir, dist)
#
#		var new_pos
#		if pos.distance_to(next) < dist:
#			new_pos = next
#			path_ofs += 1
#		else:
#			new_pos = pos + dir * dist
#
#		if path_ofs >= walk_path.size() - 1:
#			walk_stop(walk_destination)
#			return
#
#		pos = new_pos
#
#		var angle = (old_pos.angle_to_point(pos))
#		set_position(pos)
#
#		if task == PLAYER_TASKS.WALK:
#			last_deg = escoria.utils._get_deg_from_rad(angle)
#			last_dir = _get_dir_deg(last_deg, animations)
#
#			var current_animation = ""
#			if animation_sprite != null:
#				current_animation = animation_sprite.animation
##			elif animation != null:
##				current_animation = animation.current_animation
#
#			if current_animation != animations.directions[last_dir][0]:
#				animation_sprite.play(animations.directions[last_dir][0])
#
#			pose_scale = animations.directions[last_dir][1]
#
#		update_terrain()
#	else:
#		moved = false
#		set_process(false)


#func update_terrain(on_event_finished_name = null):
#	if !terrain:
#		return
#	if on_event_finished_name != null and on_event_finished_name != "setup":
#		return
#
#	var pos = position
#	z_index = pos.y if pos.y <= VisualServer.CANVAS_ITEM_Z_MAX else VisualServer.CANVAS_ITEM_Z_MAX
#
#	var color
#	if terrain_is_scalenodes:
#		last_scale = terrain.get_terrain(pos)
#		self.scale = last_scale
#	elif check_maps:
#		color = terrain.get_terrain(pos)
#		var scal = terrain.get_scale_range(color.b)
#		if scal != get_scale():
#			last_scale = scal
#			self.scale = last_scale
#
#	# Do not flip the entire player character, because that would conflict
#	# with shadows that expect to be siblings of $"sprite"
#	if pose_scale == -1 and $"sprite".scale.x > 0:
#		$"sprite".scale.x *= pose_scale
#		collision.scale.x *= pose_scale
#	elif pose_scale == 1 and $"sprite".scale.x < 0:
#		$"sprite".scale.x *= -1
#		collision.scale.x *= -1
#
##	if check_maps:
##		color = terrain.get_light(pos)
##
##	if color:
##		for s in sprites:
##			s.set_modulate(color)


"""
Sets player angle and plays according animation.
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
			escoria.report_errors("escplayer.gd:set_angle()", ["Invalid degree to turn to " + str(deg)])
	moved = true
	last_deg = deg
	last_dir = Movable._get_dir_deg(deg, animations)

	# The player may have a state animation from before, which would be
	# resumed, so we immediately force the correct idle animation
	if animation_sprite.animation != animations.idles[last_dir][0]:
		animation_sprite.play(animations.idles[last_dir][0])
	pose_scale = animations.idles[last_dir][1]
	Movable.update_terrain()


func anim_finished():
	pass

func get_camera_pos():
	if camera_position_node and get_node(camera_position_node):
		return get_node(camera_position_node).global_position
	return global_position

func get_animations_list() -> PoolStringArray:
	return animation_sprite.get_sprite_frames().get_animation_names()

func start_talking():
	if animation_sprite.is_playing():
		animation_sprite.stop()
	animation_sprite.play(animations.speaks[last_dir][0])

func stop_talking():
	if animation_sprite.is_playing():
		animation_sprite.stop()
	animation_sprite.play(animations.idles[last_dir][0])


func teleport(target, angle : Object = null) -> void:
	Movable.teleport(target, angle)


func walk_to(pos : Vector2, p_walk_context = null):
	Movable.walk_to(pos, p_walk_context)
