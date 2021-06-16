# ESCItem is a Sprite that defines an item, potentially interactive
tool
extends Area2D
class_name ESCItem


# Emitted when the mouse has entered this item
#
# #### Parameters
#
# - items: The inventory item node
signal mouse_entered_item(item)

# Emitted when the mouse has exited this item
#
# #### Parameters
#
# - items: The inventory item node
signal mouse_exited_item(item)

# Emitted when the item was left cliced
#
# #### Parameters
#
# - global_id: ID of this item
signal mouse_left_clicked_item(global_id)

# Emitted when the item was double cliced
#
# #### Parameters
#
# - global_id: ID of this item
signal mouse_double_left_clicked_item(global_id)

# Emitted when the item was right cliced
#
# #### Parameters
#
# - global_id: ID of this item
signal mouse_right_clicked_item(global_id)

# Emitted when the item walked to a destination
#
# #### Parameters
#
# - walk_context: The walk context of the command
signal arrived(walk_context)


# The global ID of this item
export(String) var global_id

# The ESC script for this item
export(String, FILE, "*.esc") var esc_script

# If true, the ESC script may have an ":exit_scene" event to manage scene changes
export(bool) var is_exit

# If true, object is considered as trigger. Allows using :trigger_in and
# :trigger_out verbs in ESC scripts. 
export(bool) var is_trigger

# The verb used for the trigger in ESC events
export(String) var trigger_in_verb = "trigger_in"

# The verb used for the trigger out ESC events
export(String) var trigger_out_verb = "trigger_out"

# If true, the player can interact with this item
export(bool) var is_interactive = true

# If true, player orients towards 'interaction_direction' as
# player character arrives.
export(bool) var player_orients_on_arrival = true

# Let the player turn to this direction when the player arrives at the
# item
export(int) var interaction_direction

# The name for the tooltip of this item
export(String) var tooltip_name

# Default action to use if object is not in the inventory
export(String) var default_action

# Default action to use if object is in the inventory
export(String) var default_action_inventory

# If action used by player is in this list, the game will wait for a second 
# click on another item to combine objects together (typical 
# `USE <X> WITH <Y>`, `GIVE <X> TO <Y>`)
export(PoolStringArray) var combine_if_action_used_among = []

# If true, combination must be done in the way it is written in ESC script
# ie. :use ON_ITEM
# If false, combination will be tried in the other way.
export(bool) var combine_is_one_way = false

# If true, then the object must have been picked up before using it.
# A false value is useful for items in the background, such as buttons.
export(bool) var use_from_inventory_only = false

# Scene based on ESCInventoryItem used in inventory for the object if it is 
# picked up, that displays and handles the item
export(PackedScene) var inventory_item_scene_file : PackedScene 

# Color used for dialogs
export(Color) var dialog_color = ColorN("white")

# If true, terrain scaling will not be applied and
# node will remain at the scale set in the scene.
export(bool) var dont_apply_terrain_scaling = false

# Speed of this item ifmovable
export(int) var speed : int = 300

# Speed damp of this item if movable
export(float) var v_speed_damp : float = 1.0

# Animations script (for walking, idling...)
export(Script) var animations

# The movable subnode
var movable: ESCMovable = null

# Reference to the animation node (null if none was found)
var animation_sprite = null

# Reference to the current terrain
var terrain: ESCTerrain

# Reference to this items collision shape node
var collision: Node

# The representation of this item in the scene. Will
# be loaded, if inventory_item_scene_file is set.
var inventory_item: ESCInventoryItem = null setget ,_get_inventory_item


# Add the movable node, connect signals, detect child nodes
# and register this item
func _ready():
	movable = ESCMovable.new()

	add_child(movable)
	
	_detect_children()
	
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	connect("input_event", self, "manage_input")
	
	# Register and connect all elements to Escoria backoffice.
	if not Engine.is_editor_hint():
		escoria.event_manager.connect("event_finished", self, "_update_terrain")
		
		escoria.object_manager.register_object(
			ESCObject.new(
				global_id,
				self
			),
			true
		)
		
		terrain = escoria.room_terrain
		
		if !is_trigger:
			connect("mouse_entered_item", escoria.inputs_manager, "_on_mouse_entered_item")
			connect("mouse_exited_item", escoria.inputs_manager, "_on_mouse_exited_item")
			connect("mouse_left_clicked_item", escoria.inputs_manager, "_on_mouse_left_clicked_item")
			connect("mouse_double_left_clicked_item", escoria.inputs_manager, "_on_mouse_left_double_clicked_item")
			connect("mouse_right_clicked_item", escoria.inputs_manager, "_on_mouse_right_clicked_item")
		else:
			connect("area_entered", self, "element_entered")
			connect("area_exited", self, "element_exited")
			connect("body_entered", self, "element_entered")
			connect("body_exited", self, "element_exited")
		
	# If object can be in the inventory, set default_action_inventory to same as
	# default_action, if default_action_inventory is not set
	if use_from_inventory_only and default_action_inventory.empty():
		default_action_inventory = default_action
	
	# Perform a first terrain scaling if we have to.
	if !is_exit or dont_apply_terrain_scaling:
		movable.last_scale = scale
		movable.update_terrain()


# Return the animation player node
func get_animation_player():
	return animation_sprite


# Return the position the player needs to walk to to interact with this
# item. That can either be a direct Position2D child or a collision shape
#
# **Returns** The interaction position
func get_interact_position() -> Vector2:
	var interact_position = null
	for c in get_children():
		if c is Position2D:
			if c.get_owner() == self:
				continue
			interact_position = c.global_position
			
	if interact_position == null and collision != null:
		interact_position = collision.global_position
		
	return interact_position


# Manage mouse button clicks on this item by sending out signals
#
# #### Parameters
#
# - _viewport: not used
# - event: Triggered event
# - _shape_idx: not used
func manage_input(
	_viewport : Viewport, 
	event : InputEvent, 
	_shape_idx : int
) -> void:
	if event is InputEventMouseButton:
				
		if event.doubleclick:
			if event.button_index == BUTTON_LEFT:
				emit_signal("mouse_double_left_clicked_item", self, event)
		else:
			if event.is_pressed():
				if event.button_index == BUTTON_LEFT:
					emit_signal("mouse_left_clicked_item", self, event)
				elif event.button_index == BUTTON_RIGHT:
					emit_signal("mouse_right_clicked_item", self, event)


# React to the mouse entering the item by emitting the respective signal
func _on_mouse_entered():
	emit_signal("mouse_entered_item", self)


# React to the mouse exiting the item by emitting the respective signal
func _on_mouse_exited():
	emit_signal("mouse_exited_item",  self)


# Another item (e.g. the player) has entered this item
# 
# #### Parameters
#
# - body: Other object that has entered the item
func element_entered(body):
	if body is ESCBackground or body.get_parent() is ESCBackground:
		return
	escoria.do("trigger_in", [global_id, body.global_id, trigger_in_verb])


# Another item (e.g. the player) has exited this element
# #### Parameters
#
# - body: Other object that has entered the item
func element_exited(body):
	if body is ESCBackground or body.get_parent() is ESCBackground:
		return
	escoria.do("trigger_out", [global_id, body.global_id, trigger_out_verb])


# Use the movable node to teleport this item to the target item
#
# #### Parameters
#
# - target: Target item to teleport to
func teleport(target: Node) -> void:
	movable.teleport(target)


# Use the movable node to make the item walk to the given position
#
# #### Parameters
#
# - pos: Position to walk to
# - p_walk_context: Walk context to use
func walk_to(pos : Vector2, p_walk_context: ESCWalkContext = null) -> void:
	movable.walk_to(pos, p_walk_context)


# Set the moving speed
#
# #### Parameters
#
# - speed_value: Set the new speed
func set_speed(speed_value : int) -> void:
	speed = speed_value


# Set the angle
#
# #### Parameters
#
# Set the angle
func set_angle(deg : int, immediate = true):
	movable.set_angle(deg, immediate)
	

# Play the talking animation
func start_talking():
	if animation_sprite.is_playing():
		animation_sprite.stop()
	animation_sprite.play(animations.speaks[movable.last_dir][0])


# Stop playing the talking animation
func stop_talking():
	if animation_sprite.is_playing():
		animation_sprite.stop()
	animation_sprite.play(animations.idles[movable.last_dir][0])


# Detect the child nodes and set respective references
func _detect_children() -> void:
	# Detect animation player
	for n in get_children():
		if n is AnimatedSprite:
			animation_sprite = n
			continue
		if n is AnimationPlayer:
			animation_sprite = n
			continue
	
	# Initialize collision variable.
	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			collision = c


# Upate the terrain when an event finished
func _update_terrain(rc: int, event_name: String) -> void:
	movable.update_terrain(event_name)


# Get inventory item from the inventory item scene
# **Returns** The inventory item of this ESCitem
func _get_inventory_item() -> ESCInventoryItem:
	if not inventory_item and inventory_item_scene_file:
		inventory_item = inventory_item_scene_file.instance()
		inventory_item.global_id = self.global_id
	return inventory_item
		
