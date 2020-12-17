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
var animation
onready var interact_positions : Dictionary = { "default": null}


# PRIVATE VARS
var area : Area2D
# Size of the item
var size : Vector2

func _ready():
	
	for n in get_children():
		if n is AnimationPlayer:
			animation = n
			continue
		if n is Area2D:
			area = n
			continue
	
	if area:
		area.connect("mouse_entered", self, "_on_mouse_entered")
		area.connect("mouse_exited", self, "_on_mouse_exited")
		area.connect("input_event", self, "manage_input")
		
	init_interact_position_with_node()
	
	if !Engine.is_editor_hint():
		escoria.register_object(self)
		connect("mouse_entered_item", escoria.inputs_manager, "_on_mouse_entered_item")
		connect("mouse_exited_item", escoria.inputs_manager, "_on_mouse_exited_item")
		connect("mouse_left_clicked_item", escoria.inputs_manager, "_on_mouse_left_clicked_item")
		connect("mouse_double_left_clicked_item", escoria.inputs_manager, "_on_mouse_left_double_clicked_item")
		connect("mouse_right_clicked_item", escoria.inputs_manager, "_on_mouse_right_clicked_item")
	
	
func get_animation_player():
	if animation == null:
		for n in get_children():
			if n is AnimationPlayer:
				animation = n
	return animation
	

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
			interact_positions.default = c.global_position
			break
		if c is CollisionShape2D or c is CollisionPolygon2D:
			interact_positions.default = c.global_position
	if interact_positions.default == null:
		interact_positions.default = self.global_position
	
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

