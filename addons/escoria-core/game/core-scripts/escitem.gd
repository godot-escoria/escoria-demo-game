tool
extends Sprite
class_name ESCItem

func get_class():
	return "ESCItem"

"""
ESCItem is a Sprite that defines an item, potentially interactive
"""

signal mouse_entered_item(global_id)
signal mouse_exited_item
signal mouse_left_clicked_item(global_id)
signal mouse_double_left_clicked_item(global_id)
signal mouse_right_clicked_item(global_id)

export(String) var global_id
export(String, FILE, "*.esc") var esc_script
# If true, the ESC script may have an ":exit_scene" event to manage scene changes
export(bool) var is_exit
export(bool) var is_interactive = true
export(bool) var player_orients_on_arrival = true
export(ESCPlayer.Directions) var interaction_direction
export(String) var tooltip_name
export(String) var default_action
# If action used by player is in the list, game will wait for a second click on another item
# to combine objects together (typical USE <X> WITH <Y>, GIVE <X> TO <Y>)
export(PoolStringArray) var combine_if_action_used_among = []
# If true, combination must be done in the way it is written in ESC script
# ie. :use ON_ITEM
# If false, combination will be tried in the other way.
export(bool) var combine_is_one_way = false
# If use_from_inventory_only is true, then the object must have been picked up before using it.
# A false value is useful for items in the background, such as buttons.
export(bool) var use_from_inventory_only = false
# Scene used in inventory for the object if it is picked up
export(PackedScene) var inventory_item_scene_file : PackedScene 


export(Color) var dialog_color = ColorN("white")

# Animation node (null if none was found)
var animation_sprite
onready var interact_positions : Dictionary = { "default": null}

# Animations script (for walking, idling...)
export(Script) var animations

# TERRAIN
var terrain : ESCTerrain
# If the terrain node type is scalenodes
var terrain_is_scalenodes : bool
var check_maps = true
var pose_scale : int
var last_scale : Vector2
var collision

# WALKING
# State machine defining the current interact state of the player
enum INTERACT_STATES {
	INTERACT_STARTED,	# 
	INTERACT_NONE,		#
	INTERACT_WALKING	# Player is walking
}
var interact_status		# Current interact status, type INTERACT_STATES

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
var params_queue : Array 



# PRIVATE VARS
var area : Area2D
# Size of the item
var size : Vector2
var last_deg : int
var last_dir : int

func _ready():
	
	for n in get_children():
		if n is AnimatedSprite:
			animation_sprite = n
			continue
		if n is AnimationPlayer:
			animation_sprite = n
			continue
		if n is Area2D:
			area = n
			continue
	
	if area:
		area.connect("mouse_entered", self, "_on_mouse_entered")
		area.connect("mouse_exited", self, "_on_mouse_exited")
		area.connect("input_event", self, "manage_input")
		
	init_interact_position_with_node()
	terrain = escoria.room_terrain
		
	if !Engine.is_editor_hint():
		escoria.register_object(self)
		connect("mouse_entered_item", escoria.inputs_manager, "_on_mouse_entered_item")
		connect("mouse_exited_item", escoria.inputs_manager, "_on_mouse_exited_item")
		connect("mouse_left_clicked_item", escoria.inputs_manager, "_on_mouse_left_clicked_item")
		connect("mouse_double_left_clicked_item", escoria.inputs_manager, "_on_mouse_left_double_clicked_item")
		connect("mouse_right_clicked_item", escoria.inputs_manager, "_on_mouse_right_clicked_item")
	
	update_terrain()


func _process(time):
	if Engine.is_editor_hint():
		return
	
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






func get_animation_player():
	if animation_sprite == null:
		for n in get_children():
			if n is AnimationPlayer:
				animation_sprite = n
	return animation_sprite
	

"""
Initialize the interact_position attribute by searching for a Position2D
node in children nodes. 
If any is found, the first one is used as interaction position with this hotspot.
If none is found, we use the CollisionShape2D or CollisionPolygon2D child node's 
position instead.
"""
func init_interact_position_with_node():
	for c in get_children():
		if c is Position2D:
			# If the position2D node is part of the hotspot, it means it is not an interact position
			# but a dialog position for example. Interact position node must be set in the room scene.
			if c.get_owner() == self:
				continue
			interact_positions.default = c.global_position
			break
		if c is CollisionShape2D or c is CollisionPolygon2D:
			interact_positions.default = c.global_position	
		
	
func manage_input(viewport : Viewport, event : InputEvent, shape_idx : int):
	if event is InputEventMouseButton:
#		var p = get_global_mouse_position()
		if event.doubleclick:
			if event.button_index == BUTTON_LEFT:
				emit_signal("mouse_double_left_clicked_item", global_id, event)
		else:
			if event.is_pressed():
				if event.button_index == BUTTON_LEFT:
					emit_signal("mouse_left_clicked_item", global_id, event)
				if event.button_index == BUTTON_RIGHT:
					emit_signal("mouse_right_clicked_item", global_id, event)
		

func _on_mouse_entered():
	emit_signal("mouse_entered_item", global_id)

func _on_mouse_exited():
	emit_signal("mouse_exited_item")

func update_terrain(on_event_finished_name = null):
	if !terrain or terrain == null or !is_instance_valid(terrain):
		return
	if on_event_finished_name != null and on_event_finished_name != "setup":
		return
	if is_exit:
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
	# with shadows that expect to be siblings of $texture
	if pose_scale == -1 and $texture.scale.x > 0:
		$texture.scale.x *= pose_scale
		collision.scale.x *= pose_scale
	elif pose_scale == 1 and $texture.scale.x < 0:
		$texture.scale.x *= -1
		collision.scale.x *= -1

#	if check_maps:
#		color = terrain.get_light(pos)
#
#	if color:
#		for s in sprites:
#			s.set_modulate(color)



func teleport(target, angle : Object = null) -> void:
	"""
	Teleports the item on target position.
	target can be Vector2 or Object
	"""
	if typeof(target) == TYPE_VECTOR2:
		printt("Item teleported at position", target, "with angle", angle)
		position = target
	elif typeof(target) == TYPE_OBJECT:
		if target.get("interact_positions") != null:
			position = target.interact_positions.default #.global_position
		else:
			position = target.position
		printt("Item teleported at", target.name, "position", position, "with angle", angle)
	else:
		escoria.report_errors("escitem.gd:teleport()", ["Target to teleport to is null or unusable (" + target + ")"])

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
#		escoria.esc_level_runner.finished(walk_context)
		escoria.esc_level_runner.finished()
		walk_context = null
	emit_signal("arrived")


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
		escoria.report_errors("escitem.gd:_get_dir_deg()", ["No direction found for " + str(deg)])
	
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
	



