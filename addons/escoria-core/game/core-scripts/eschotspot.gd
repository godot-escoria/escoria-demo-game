tool
extends Area2D
class_name ESCHotspot

func get_class():
	return "ESCHotspot"

"""
ESCHotspot is an Area2D (hotspot).
A hotspot is a simple area that can be defined by the user and is thus invisible
Usually, hotspots are used to define areas of the background that the player can 
look at.
"""

signal mouse_entered_hotspot(global_id)
signal mouse_exited_hotspot
signal mouse_left_clicked_hotspot(global_id, click_position)
signal mouse_double_left_clicked_hotspot(global_id, click_position)
signal mouse_right_clicked_hotspot(global_id, click_position)

export(String) var global_id
export(bool) var is_exit
export(String, FILE, "*.esc") var esc_script
export(bool) var is_interactive = true
export(bool) var player_orients_on_arrival = true
export(ESCPlayer.Directions) var interaction_direction
export(String) var tooltip_name
export(String) var default_action
# If action used by player is in the list, game will wait for a second click on another item
# to combine objects together (typical USE <X> WITH <Y>, GIVE <X> TO <Y>)
export(PoolStringArray) var combine_if_action_used_among = []
export(Color) var dialog_color = ColorN("white")

# Detected interact position set by a Position2D node OUTSIDE OF THE HOTSPOT SCENE.
# You have to add a child to the INSTANCED HOTSPOT SCENE, IN THE ROOM SCENE.
export(Dictionary) var interact_positions : Dictionary = { "default": null}

var collision

var terrain : ESCTerrain
# If the terrain node type is scalenodes
var terrain_is_scalenodes : bool
var check_maps = true

var pose_scale : int
var last_scale : Vector2

func _ready():
	if !Engine.is_editor_hint():
		escoria.register_object(self)
		connect("mouse_entered_hotspot", escoria.inputs_manager, "_on_mouse_entered_hotspot")
		connect("mouse_exited_hotspot", escoria.inputs_manager, "_on_mouse_exited_hotspot")
		connect("mouse_left_clicked_hotspot", escoria.inputs_manager, "_on_mouse_left_clicked_hotspot")
		connect("mouse_right_clicked_hotspot", escoria.inputs_manager, "_on_mouse_right_clicked_hotspot")
	
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	connect("input_event", self, "manage_input")
	init_interact_position_with_node()
	terrain = escoria.room_terrain
	
	
	update_terrain()
	
	
func init_interact_position_with_node():
	"""
	Initialize the interact_position attribute by searching for a Position2D
	node in children nodes. 
	If any is found, the first one is used as interaction position with this hotspot.
	If none is found, we use the CollisionShape2D or CollisionPolygon2D child node's 
	position instead.
	"""
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
				emit_signal("mouse_double_left_clicked_hotspot", global_id, event)
		else:
			if event.is_pressed():
				if event.button_index == BUTTON_LEFT:
					emit_signal("mouse_left_clicked_hotspot", global_id, event)
				if event.button_index == BUTTON_RIGHT:
					emit_signal("mouse_right_clicked_hotspot", global_id, event)


func _on_mouse_entered():
	emit_signal("mouse_entered_hotspot", global_id)


func _on_mouse_exited():
	emit_signal("mouse_exited_hotspot")


func get_item_child_if_any():
	for c in get_children():
		if c is ESCItem:
			return c


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
