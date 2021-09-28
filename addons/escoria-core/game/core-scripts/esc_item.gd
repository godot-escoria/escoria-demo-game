# ESCItem is a Sprite that defines an item, potentially interactive
tool
extends Area2D
class_name ESCItem, "res://addons/escoria-core/design/esc_item.svg"


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

# Wether this item is movable
export(bool) var is_movable = false

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
export(PackedScene) var inventory_item_scene_file: PackedScene 

# Color used for dialogs
export(Color) var dialog_color = ColorN("white")

# If true, terrain scaling will not be applied and
# node will remain at the scale set in the scene.
export(bool) var dont_apply_terrain_scaling = false

# Speed of this item ifmovable
export(int) var speed: int = 300

# Speed damp of this item if movable
export(float) var v_speed_damp: float = 1.0

# The node used to play animations
export(NodePath) var animation_player_node: NodePath = "" \
		setget _set_animation_player_node

# ESCAnimationsResource (for walking, idling...)
var animations: ESCAnimationResource

# Reference to the animation node (null if none was found)
var animation_sprite = null

# Reference to the sprite node
var _sprite_node: Node = null

# Reference to the current terrain
var terrain: ESCTerrain

# Reference to this items collision shape node
var collision: Node

# The representation of this item in the scene. Will
# be loaded, if inventory_item_scene_file is set.
var inventory_item: ESCInventoryItem = null setget ,_get_inventory_item


# The movable subnode
var _movable: ESCMovable = null

# The identified animation player
var _animation_player: ESCAnimationPlayer = null


# Add the movable node, connect signals, detect child nodes
# and register this item
func _ready():
	self.pause_mode = Node.PAUSE_MODE_STOP
	
	_detect_children()
	
	if not self.is_connected("mouse_entered", self, "_on_mouse_entered"):
		connect("mouse_entered", self, "_on_mouse_entered")
	if not self.is_connected("mouse_exited", self, "_on_mouse_exited"):
		connect("mouse_exited", self, "_on_mouse_exited")
	
	# Register and connect all elements to Escoria backoffice.
	if not Engine.is_editor_hint():
		
		if is_movable:
			_movable = ESCMovable.new()

			add_child(_movable)
	
		if not escoria.event_manager.is_connected(
			"event_finished",
			self, 
			"_update_terrain"
		):
			escoria.event_manager.connect(
				"event_finished", 
				self, 
				"_update_terrain"
			)
		
		escoria.object_manager.register_object(
			ESCObject.new(
				global_id,
				self
			),
			true
		)
		
		terrain = escoria.room_terrain
		
		if !is_trigger:
			if not self.is_connected(
				"mouse_entered_item", 
				escoria.inputs_manager, 
				"_on_mouse_entered_item"
			):
				connect(
					"mouse_entered_item", 
					escoria.inputs_manager, 
					"_on_mouse_entered_item"
				)
			if not self.is_connected(
				"mouse_exited_item", 
				escoria.inputs_manager, 
				"_on_mouse_exited_item"
			):
				connect(
					"mouse_exited_item", 
					escoria.inputs_manager, 
					"_on_mouse_exited_item"
				)
			if not self.is_connected(
				"mouse_left_clicked_item", 
				escoria.inputs_manager, 
				"_on_mouse_left_clicked_item"
			):
				connect(
					"mouse_left_clicked_item", 
					escoria.inputs_manager, 
					"_on_mouse_left_clicked_item"
				)
			if not self.is_connected(
				"mouse_double_left_clicked_item", 
				escoria.inputs_manager, 
				"_on_mouse_left_double_clicked_item"
			):
				connect(
					"mouse_double_left_clicked_item", 
					escoria.inputs_manager, 
					"_on_mouse_left_double_clicked_item"
				)
			if not self.is_connected(
				"mouse_right_clicked_item", 
				escoria.inputs_manager, 
				"_on_mouse_right_clicked_item"
			):
				connect(
					"mouse_right_clicked_item", 
					escoria.inputs_manager, 
					"_on_mouse_right_clicked_item"
				)
		else:
			if not self.is_connected("area_entered", self, "element_entered"):
				connect("area_entered", self, "element_entered")
			if not self.is_connected("area_exited", self, "element_exited"):
				connect("area_exited", self, "element_exited")
			if not self.is_connected("body_entered", self, "element_entered"):
				connect("body_entered", self, "element_entered")
			if not self.is_connected("body_exited", self, "element_exited"):
				connect("body_exited", self, "element_exited")
		
	# If object can be in the inventory, set default_action_inventory to same as
	# default_action, if default_action_inventory is not set
	if use_from_inventory_only and default_action_inventory.empty():
		default_action_inventory = default_action
	
	# Perform a first terrain scaling if we have to.
	if (!is_exit or dont_apply_terrain_scaling) and is_movable:
		_movable.last_scale = scale
		_movable.update_terrain()

# Manage mouse button clicks on this item by sending out signals
#
# #### Parameters
#
# - event: Triggered event
func _input(event: InputEvent) -> void:
	if not escoria.current_state == escoria.GAME_STATE.DEFAULT:
		return
	if event is InputEventMouseButton and event.is_pressed():
		var p = get_global_mouse_position()
		var mouse_in_shape: bool = false
		var colliders = get_world_2d().direct_space_state.intersect_point(
			p,
			32, 
			[], 
			2147483647,
			true,
			true
		)
		for _owner in get_shape_owners():
			for _shape_id in range(0, shape_owner_get_shape_count(_owner)):
				for _collider in colliders:
					if _collider.collider == self and\
							_collider.shape == _shape_id:
						mouse_in_shape = true
		if mouse_in_shape:
			if event.doubleclick and event.button_index == BUTTON_LEFT:
				emit_signal("mouse_double_left_clicked_item", self, event)
			elif event.button_index == BUTTON_LEFT:
				emit_signal("mouse_left_clicked_item", self, event)
			elif event.button_index == BUTTON_RIGHT:
				emit_signal("mouse_right_clicked_item", self, event)


# Return the animation player node
func get_animation_player() -> Node:
	if _animation_player == null:
		var player_node_path = animation_player_node
		if player_node_path == "":
			for child in self.get_children():
				if child is AnimatedSprite or \
						child is AnimationPlayer:
					player_node_path = child.get_path()
		if not has_node(player_node_path):
			escoria.logger.warning(
				"Can not find node at path %s" % player_node_path
			)
		_animation_player = ESCAnimationPlayer.new(get_node(player_node_path))
	return _animation_player


# Return the position the player needs to walk to to interact with this
# item. That can either be a direct Position2D child or a collision shape
#
# **Returns** The interaction position
func get_interact_position() -> Vector2:
	var interact_position = null
	for c in get_children():
		if c is Position2D:
			interact_position = c.global_position
			
	if interact_position == null and collision != null:
		interact_position = collision.global_position
		
	return interact_position


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
# - target: Target node to teleport to
func teleport(target: Node) -> void:
	_movable.teleport(target)


# Use the movable node to teleport this item to the target position
#
# #### Parameters
#
# - target: Vector2 position to teleport to
func teleport_to(target: Vector2) -> void:
	_movable.teleport_to(target)
	

# Use the movable node to make the item walk to the given position
#
# #### Parameters
#
# - pos: Position to walk to
# - p_walk_context: Walk context to use
func walk_to(pos: Vector2, p_walk_context: ESCWalkContext = null) -> void:
	_movable.walk_to(pos, p_walk_context)


# Set the moving speed
#
# #### Parameters
#
# - speed_value: Set the new speed
func set_speed(speed_value: int) -> void:
	speed = speed_value
	

# Check wether this item moved
func has_moved() -> bool:
	return _movable.moved if is_movable else false


# Return the sprite node
func get_sprite() -> Node:
	if _sprite_node == null:
		for child in self.get_children():
			if child is AnimatedSprite or child is Sprite:
				_sprite_node = child
	if _sprite_node == null:
		escoria.logger.error(
			"No sprite node found in the scene %s" % get_path()
		)
	return _sprite_node


# Set the angle
#
# #### Parameters
#
# - deg: The angle degree to set
# - wait: Wait this amount of seconds until continuing with turning around
func set_angle(deg: int, wait: float = 0.0):
	_movable.set_angle(deg, wait)


# Turn to face another object
#
# #### Parameters
#
# - deg: The angle degree to set
# - float Wait this amount of seconds until continuing with turning around
func turn_to(object: Node, wait: float = 0.0):
	_movable.turn_to(object, wait)


# Play the talking animation
func start_talking():
	if get_animation_player().is_playing():
		get_animation_player().stop()
	get_animation_player().play(animations.speaks[_movable.last_dir].animation)


# Stop playing the talking animation
func stop_talking():
	if get_animation_player().is_playing():
		get_animation_player().stop()
	get_animation_player().play(animations.idles[_movable.last_dir].animation)


# Detect the child nodes and set respective references
func _detect_children() -> void:
	# Initialize collision variable.
	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			collision = c


# Upate the terrain when an event finished
func _update_terrain(rc: int, event_name: String) -> void:
	if is_movable:
		_movable.update_terrain(event_name)


# Get inventory item from the inventory item scene
# **Returns** The inventory item of this ESCitem
func _get_inventory_item() -> ESCInventoryItem:
	if not inventory_item and inventory_item_scene_file:
		inventory_item = inventory_item_scene_file.instance()
		inventory_item.global_id = self.global_id
	return inventory_item


func _get_property_list():
	var properties = []
	properties.append({
		"name": "animations",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "ESCAnimationResource"
	})
	return properties


# Set the node path to the animation player
#
# #### Parameters
#
# - node_path: Path to the player node
func _set_animation_player_node(node_path: NodePath):
	if not Engine.is_editor_hint():
		return
	
	if node_path == "":
		animation_player_node = node_path
		return
		
	assert(has_node(node_path), "Node with path %s not found" % node_path)
	assert(
		get_node(node_path) is AnimatedSprite or \
				get_node(node_path) is AnimationPlayer,
		"Selected node has to be an AnimatedSprite or AnimationPlayer node"
	)
	
	animation_player_node = node_path
