@tool
@icon("res://addons/escoria-core/design/esc_item.svg")
# An ``ESCItem`` defines a (usually interactive) item in the game.
#
# When interacting with an ``ESCItem``, the game character will automatically
# walk to an ``ESCLocation`` that is created as a child of an ``ESCItem``.
#
# By selecting the "Is Exit" checkbox when you create an ``ESCItem``
# node, Escoria will look for an ``:exit_scene`` event in the attached script file.
# Any commands you place in the ``:exit_scene`` event will be run when the player
# chooses to "use" the exit - for example, saying a goodbye, or running a
# cutscene. Place a ``change_scene`` command inside this event to move the
# character to the next room.
extends Area2D
class_name ESCItem




# List of forbidden characters in global_ids
const FORBIDDEN_CHARACTERS: String = "['\"]"


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


## The global ID of this item
@export var global_id: String

## The ASHES script for this item
@export_file("*.esc", "*.ash") var esc_script: String

## The node that references the camera position and zoom if this item is used
## as a camera target
@export var camera_node: NodePath

@export_group("Display")

## The name for the tooltip of this item.
@export var tooltip_name: String

@export_group("","")
@export_group("Item Behavior")

## Whether this item is movable. A movable item will be scaled with the terrain
## and be moved with commands like ``teleport`` and ``turn_to``.
@export var is_movable: bool = false

## Color used for dialogs if that item talks.
@export var dialog_color: Color = Color(1,1,1,1)

## Default action to use if object is not in the inventory.
@export var default_action: String

## If action used by player is in this list, the game will wait for a second
## click on another item to combine objects together (typically
## `USE <X> WITH <Y>`, `GIVE <X> TO <Y>`)
@export var combine_when_selected_action_is_in: PackedStringArray = []

## If enabled, the ASHES script may have an :exit_scene event to manage scene changes.
## For simple exits that do not require scripted actions, the ESCExit node may be
## preferred.
@export var is_exit: bool

## Defines this item as acting as a trigger if enabled.
## Allows using specific events (defined in trigger_in_verb and trigger_out_verb
## properties) in ASHES scripts.
@export var is_trigger: bool

## Event name that is activated when another item enters the area defined by the
## trigger item. By default, "trigger_in".
@export var trigger_in_verb: String = "trigger_in"

## Event name that is activated when another item exits the area defined by the
## trigger item. By default, "trigger_out".
@export var trigger_out_verb: String = "trigger_out"

## Defines whether the player can interact with this item. If false, the item
## will not react to inputs and mouse hovers. 
@export var is_interactive: bool = true


@export_subgroup("Hover Behavior")

## Defines whether Escoria will manage a specific hover behavior when the item
## is focused. All options below can be used together.
## This can also be expanded or overriden in your ESCGame implementation 
## (in methods ``element_focused()`` and ``element_unfocused()``).
@export var hover_enabled: bool = false

## If hover is enabled, applies this color modulation on the ESCItem sprite.
@export var hover_modulate: Color = Color.WHITE
var _previous_color_modulate: Color

## If hover is enabled, replaces this ESCItem sprite texture by this one.
@export var hover_texture: Texture2D = null
var _previous_texture: Texture2D = null

## If hover is enabled, applies this shader to the ESCItem sprite.
@export var hover_shader: ShaderMaterial = null

@export_subgroup("","")

@export_group("","")
@export_group("Player behavior on arrival")

## Whether player character orients towards 'interaction_angle' as it arrives at 
## the item's interaction position.
@export var player_orients_on_arrival: bool = true

## If 'player_orients_on_arrival' is enabled, let the player character turn to 
## this angle when it arrives at the item's interaction position.
@export var interaction_angle: int

@export_group("","")
@export_group("Inventory")

## Default action to use if object is in the inventory
@export var default_action_inventory: String

## If enabled, combination must be done in the way it is written in ASHES script
## ie. :use ON_ITEM
## If disabled, combination will be tried in the other way.
@export var combine_is_one_way: bool = false

## If enabled, then the object must have been picked up before using it.
## Keep disabled for items in the background, such as buttons.
@export var use_from_inventory_only: bool = false

## The visual representation for this item when it's in the inventory
@export var inventory_texture: Texture2D = null:
		get = _get_inventory_texture

## The visual representation for this item when it's in the inventory and hovered
@export var inventory_texture_hovered: Texture2D = null:
		get = _get_inventory_texture_hovered

@export_group("","")
@export_group("Movement")

## If enabled, terrain scaling will not be applied and
## node will remain at the scale set in the scene.
@export var dont_apply_terrain_scaling: bool = false

## Speed of this item if movable
@export var speed: int = 300

## Speed damp of this item if movable
@export var v_speed_damp: float = 1.0

@export_group("","")
@export_group("Animations")

## Animations resource for the item (walking, idling...)
@export var animations: ESCAnimationResource: 
		set = set_animations

## The node used to play animations
@export var animation_player_node: NodePath = "":
		set = _set_animation_player_node

@export_group("","")
@export_group("Custom actions")

## Custom data dictionary to ease customization and custom command creation.
## Avoid name collision using proper key names.
@export var custom_data: Dictionary = {}

@export_group("","")

# Reference to the animation node (null if none was found)
var animation_sprite = null

# Reference to the current terrain
var terrain: ESCTerrain

# Reference to this items collision shape node
var collision: Node


# Reference to the sprite node
var _sprite_node: Node = null

# The movable subnode
var _movable: ESCMovable = null

# The identified animation player
var _animation_player: ESCAnimationPlayer = null

# Whether to force regsitration with the object manager. Defaults to false.
var _force_registration: bool = false

# Warnings for scene.
var _scene_warnings: PackedStringArray = []

# Add the movable node, connect signals, detect child nodes
# and register this item
func _ready():
	self.process_mode = Node.PROCESS_MODE_PAUSABLE

	_detect_children()

	# We add ourselves to this group so we can easily get a reference to all
	# items in a scene tree.
	if not Engine.is_editor_hint():
		add_to_group(escoria.GROUP_ITEM_CAN_COLLIDE)
		if is_trigger:
			add_to_group(escoria.GROUP_ITEM_TRIGGERS)

	validate_animations(animations)
	validate_exported_parameters()

	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

	# Register and connect all elements to Escoria backoffice.
	if not Engine.is_editor_hint():

		if is_movable:
			_movable = ESCMovable.new()
			add_child(_movable)

		if not escoria.event_manager.event_finished.is_connected(_update_terrain):
			escoria.event_manager.event_finished.connect(_update_terrain)

		escoria.object_manager.register_object(
			ESCObject.new(
				global_id,
				self
			),
			null,
			_force_registration
		)

		terrain = escoria.room_terrain if is_instance_valid(escoria.room_terrain) else null

		if escoria.object_manager.get_object(global_id).state == ESCObject.STATE_DEFAULT \
				and get_animation_player() != null:
			escoria.object_manager.get_object(global_id) \
					.set_state(get_animation_player().get_animation())
			if is_movable:
				escoria.object_manager.get_object(global_id).node \
						._movable.last_dir = animations.get_direction_id_from_animation_name(
							get_animation_player().get_animation()
						)
			

		if escoria.object_manager.get_object(global_id).state == ESCObject.STATE_DEFAULT \
				and escoria.object_manager.get_object(global_id).node.get_animation_player() != null:
			escoria.object_manager.get_object(global_id) \
					.set_state(get_animation_player().get_animation())
			if is_movable:
				escoria.object_manager.get_object(global_id).node._movable.last_dir = 1
						#animations.get_direction_id_from_animation_name(
							#.get_animation_player().get_animation()
						#)
			

		if !is_trigger:
			if not self.is_connected(
					"mouse_entered_item", 
					escoria.inputs_manager._on_mouse_entered_item
			):
				mouse_entered_item.connect(
					escoria.inputs_manager._on_mouse_entered_item
				)
			if not self.is_connected(
					"mouse_exited_item", 
					escoria.inputs_manager._on_mouse_exited_item
			):
				mouse_exited_item.connect(
					escoria.inputs_manager._on_mouse_exited_item
				)
			if not self.is_connected(
					"mouse_left_clicked_item", 
					escoria.inputs_manager._on_mouse_left_clicked_item
			):
				mouse_left_clicked_item.connect(
					escoria.inputs_manager._on_mouse_left_clicked_item
				)
			if not self.is_connected(
				"mouse_double_left_clicked_item",
				escoria.inputs_manager._on_mouse_left_double_clicked_item
			):
				mouse_double_left_clicked_item.connect(
					escoria.inputs_manager._on_mouse_left_double_clicked_item
				)
			if not self.is_connected(
				"mouse_right_clicked_item",
				escoria.inputs_manager._on_mouse_right_clicked_item
			):
				mouse_right_clicked_item.connect(
					escoria.inputs_manager._on_mouse_right_clicked_item
				)
		else: # Item is a trigger
			if not self.is_connected("area_entered", element_entered):
				area_entered.connect(element_entered)
			if not self.is_connected("area_exited", element_exited):
				area_exited.connect(element_exited)
			if not self.is_connected("body_entered", element_entered):
				body_entered.connect(element_entered)
			if not self.is_connected("body_exited", element_exited):
				body_exited.connect(element_exited)

		# If object can be in the inventory, set default_action_inventory to same as
		# default_action, if default_action_inventory is not set
		if use_from_inventory_only and default_action_inventory.is_empty():
			default_action_inventory = default_action

		# Perform a first terrain scaling if we have to.
		if (not is_exit or dont_apply_terrain_scaling) and is_movable:
			_movable.last_scale = scale
			_movable.update_terrain()


func connect_trigger_events():
	assert(is_trigger)
	monitoring = true

# Validates the various exported parameters so we get immediate crash.
func validate_exported_parameters() -> void:
	var regex = RegEx.new()
	regex.compile(FORBIDDEN_CHARACTERS)
	var result = regex.search(global_id)
	if result:
		escoria.logger.error(
				self,
				"Forbidden character in global_id %s (path: %s)"
						% [global_id, get_path()]
				)
	if global_id.is_empty():
		escoria.logger.error(
				self,
				"global_id of item is empty (node name : %s, path: %s)"
						% [name, get_path()]
				)


func disconnect_trigger_events():
	assert(is_trigger)
	monitoring = false


# Mouse exited happens on any item that mouse cursor exited, even those UNDER
# the top level of overlapping stack.
func _on_mouse_exited():
	if escoria.inputs_manager.hover_stack.has(self):
		escoria.inputs_manager.hover_stack.erase_item(self)
	escoria.inputs_manager.unset_hovered_node(self)
	_apply_unhover_behavior()


class HoverStackSorter:
	static func sort_ascending_z_index(a, b):
		if a.z_index < b.z_index:
			return true
		return false


# Manage input events on the item
#
# #### Parameters
#
# - _viewport: the viewport node the event entered
# - event: the input event
# - _shape_idx is the child index of the clicked Shape2D.
func _on_input_event(_viewport: Object, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseMotion:
		var physics2d_dss: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var params := PhysicsPointQueryParameters2D.new()
		params.position = get_global_mouse_position()
		params.collision_mask = 0x7FFFFFFF
		params.collide_with_areas = true
		var colliding: Array = physics2d_dss.intersect_point(params, 32)
		var colliding_nodes = []
		for c in colliding:
			if c.collider.get("global_id") \
					and escoria.action_manager.is_object_actionable(c.collider.global_id):
				colliding_nodes.push_back(c.collider)

		if colliding_nodes.is_empty():
			return
		colliding_nodes.sort_custom(Callable(HoverStackSorter, "sort_ascending_z_index"))
		escoria.inputs_manager.hover_stack.clear()
		escoria.inputs_manager.hover_stack.add_items(colliding_nodes)
		escoria.inputs_manager.set_hovered_node(colliding_nodes.back())
	
# Manage mouse button clicks on this item by sending out signals
#
# #### Parameters
#
# - input_event: Triggered event
func _unhandled_input(input_event: InputEvent) -> void:
	# If this is a trigger, then escoria.inputs_manager is not wired up to
	# receive the signals this function might dispatch. In particular,
	# calling get_tree().set_input_as_handled() unnecessarily will prevent
	# the ESCBackground from being able to process the event.
	# See https://github.com/godot-escoria/escoria-issues/issues/147.
	if is_trigger:
		return

	var event = input_event
	# Note that event could be InputEventMouseButton, InputEventJoypadButton,
	# or something else. As such, the value of the `button_index` property
	# must be read in the context of the type of input event.
	if input_event is InputEventJoypadButton:
		if not input_event.is_action_pressed(escoria.inputs_manager.ESC_UI_PRIMARY_ACTION):
			return

		# For now, rather than refactor input handling to be more generic
		# to accommodate gamepad support, we create a synthetic mouse event
		# based on the InputEventJoypadButton.
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.double_click = false
		event.button_pressed = true
		# ESCActionManager expects to read the position off of the event.
		event.position = get_global_mouse_position()

	if event is InputEventMouseButton and event.is_pressed():
		if not escoria.current_state == escoria.GAME_STATE.DEFAULT:
			escoria.logger.info(
				self,
				"Current game state doesn't accept interactions."
			)
			return
		var p = get_global_mouse_position()
		if _is_in_shape(p) and escoria.action_manager.is_object_actionable(global_id):
			if event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
				mouse_double_left_clicked_item.emit(self, event)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				mouse_left_clicked_item.emit(self, event)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				mouse_right_clicked_item.emit(self, event)
				get_viewport().set_input_as_handled()


# To display warnings in the scene tree should there be any.
func _get_configuration_warnings():
	validate_animations(animations)
	return "\n".join(_scene_warnings)


func _is_in_shape(position: Vector2) -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = position
	params.collision_mask = 2147483647
	params.collide_with_areas = true
	var colliders = get_world_2d().direct_space_state.intersect_point(
		params,
		32
	)
	for _owner in get_shape_owners():
		for _shape_id in range(0, shape_owner_get_shape_count(_owner)):
			for _collider in colliders:
				if _collider.collider == self and _collider.shape == _shape_id:
					return true
	return false


# Validates the ESCAnimationResource if it exists. Note that we pass in the
# ESCAnimationResource as an argument so that it can also be used to validate
# an ESCAnimationResource prior to being set.
#
# #### Parameters
#
# - animation_resource: the ESCAnimationResource to validate.
func validate_animations(animations_resource: ESCAnimationResource) -> void:
	if not is_instance_valid(animations_resource):
		return

	# This initialization must always be here since this is a tool script.
	_scene_warnings = []

	if is_instance_valid(animations_resource):
		_validate_animations_property_all_not_null(animations_resource.dir_angles, "dir_angles")

		var num_dir_angles = animations_resource.dir_angles.size()

		if animations_resource.directions.size() != num_dir_angles:
			_scene_warnings.append("%s animation angles specified but %s 'directions' animation(s) given. [%s]" \
				% [num_dir_angles, animations_resource.directions.size(), _get_identifier_as_key_value()])
		else:
			_validate_animations_property_all_not_null(animations_resource.directions, "directions")

		if animations_resource.idles.size() != num_dir_angles:
			_scene_warnings.append("%s animation angles specified but %s 'idles' animation(s) given. [%s]" \
				% [num_dir_angles, animations_resource.idles.size(), _get_identifier_as_key_value()])
		else:
			_validate_animations_property_all_not_null(animations_resource.idles, "idles")

		if animations_resource.speaks.size() != num_dir_angles:
			_scene_warnings.append("%s animation angles specified but %s 'speaks' animation(s) given. [%s]" \
				% [num_dir_angles, animations_resource.speaks.size(), _get_identifier_as_key_value()])
		else:
			_validate_animations_property_all_not_null(animations_resource.speaks, "speaks")

	if Engine.is_editor_hint():
		update_configuration_warnings()
	elif _scene_warnings.size() > 0:
		escoria.logger.error(
			self,
			", ".join(_scene_warnings)
		)


# Setter for the animations property.
func set_animations(p_animations: ESCAnimationResource) -> void:
	if p_animations == null:
		return

	animations = p_animations

	if not animations.is_connected("changed", Callable(self, "_validate_animations")):
		animations.connect("changed", Callable(self, "_validate_animations"))


# Return the animation player node
func get_animation_player() -> Node:
	if _animation_player == null:
		var player_node_path = animation_player_node
		if player_node_path.is_empty():
			for child in self.get_children():
				if child is AnimatedSprite2D or \
						child is AnimationPlayer:
					player_node_path = child.get_path()
		if player_node_path.is_empty():
			escoria.logger.warn(
				self,
				"Can not find animation_player or animated sprite for %s." % global_id
			)
		elif not has_node(player_node_path):
			escoria.logger.warn(
				self,
				"Can not find animation_player node at path %s for %s." % [player_node_path, global_id]
			)
		else:
			_animation_player = ESCAnimationPlayer.new(
				get_node(player_node_path)
			)
	return _animation_player


# Return the position the player needs to walk to to interact with this
# item. That can either be a direct Position2D child or a collision shape
#
# **Returns** The interaction position
func get_interact_position() -> Vector2:
	var pos_2d_count: int = 0
	var pos_2d_position = null

	var esclocation_count = 0
	var esclocation_position = null

	var interact_count = 0
	var interact_position = null

	for c in get_children():
		if c is Marker2D:
			# Identify any Postion2D nodes
			if c is ESCLocation:
				esclocation_count += 1
				esclocation_position = c.global_position
			elif c is ESCInteractionLocation:
				interact_count += 1
				interact_position = c.global_position
			else:
				# This will catch all other Position2D related nodes
				# including dialog locations and native Position2D nodes.
				pos_2d_count += 1
				pos_2d_position = c.global_position

	if interact_position == null and \
		esclocation_position == null and is_instance_valid(collision):
		escoria.logger.warn(
			self,
			"No ESCLocation found to walk to for object " +
			"%s. Middle of collision shape will be used." % global_id)
		return collision.global_position

	if interact_count > 0:
		if interact_count > 1:
			escoria.logger.warn(
				self,
				"Multiple ESCInteractionLocations found to walk to for " +
				"object %s. Last one will be used." % global_id)
		return interact_position

	if esclocation_count > 1:
		escoria.logger.warn(
			self,
			"Multiple ESClocations found to walk to for object " +
			"%s. Last one will be used." % global_id)
	return esclocation_position


# React to the mouse entering the item by emitting the respective signal
func mouse_entered():
	if escoria.action_manager.is_object_actionable(global_id):
		mouse_entered_item.emit(self)
		_apply_hover_behavior()



# React to the mouse exiting the item by emitting the respective signal
func do_mouse_exited():
	mouse_exited_item.emit(self)

# Another item (e.g. the player) has entered this item
#
# #### Parameters
#
# - body: Other object that has entered the item
func element_entered(body):
	if body is ESCBackground or body.get_parent() is ESCBackground:
		return
	escoria.action_manager.do(
		escoria.action_manager.ACTION.TRIGGER_IN,
		[global_id, body.global_id, trigger_in_verb]
	)


# Another item (e.g. the player) has exited this element
#
# #### Parameters
#
# - body: Other object that has exited the item
func element_exited(body):
	if body is ESCBackground or body.get_parent() is ESCBackground:
		return
	escoria.action_manager.do(
		escoria.action_manager.ACTION.TRIGGER_OUT,
		[global_id, body.global_id, trigger_out_verb]
	)


# Use the movable node to teleport this item to the target item
#
# #### Parameters
#
# - target: Target node to teleport to
func teleport(target: Node) -> void:
	if is_movable:
		_movable.teleport(target)
	else:
		escoria.logger.warn(
			self,
			"Node %s cannot \"teleport\". Its \"is_movable\" parameter is false." %self
		)


# Use the movable node to teleport this item to the target position
#
# #### Parameters
#
# - target: Vector2 position to teleport to
func teleport_to(target: Vector2) -> void:
	if is_movable:
		_movable.teleport_to(target)
	else:
		escoria.logger.warn(
			self,
			"Node %s cannot \"teleport_to\". Its \"is_movable\" parameter is false." %self
		)


# Use the movable node to make the item walk to the given position
#
# #### Parameters
#
# - pos: Position to walk to
# - p_walk_context: Walk context to use
func walk_to(pos: Vector2, p_walk_context: ESCWalkContext = null) -> void:
	if is_movable:
		_movable.walk_to(pos, p_walk_context)
	else:
		escoria.logger.warn(
			self,
			"Node %s cannot use \"walk_to\". Its \"is_movable\" parameter is false." %self
		)


# Stop the movable node immediately and remain where it is at this moment,
# or teleport it directly at destination position if 'to_target' is true.
#
# #### Parameters
#
# - to_target: if true, the movable node is teleport directly at its target
# destination
func stop_walking_now(to_target: bool = false) -> void:
	if is_movable:
		var where: Vector2 = position
		if to_target:
			where = _movable.walk_destination
		_movable.walk_stop(where)
	else:
		escoria.logger.warn(
			self,
			"Node %s cannot use \"stop_walking_now\". Its \"is_movable\" parameter is false." %self
		)


# Set the moving speed
#
# #### Parameters
#
# - speed_value: Set the new speed
func set_velocity(speed_value: int) -> void:
	speed = speed_value


# Check whether this item moved
func has_moved() -> bool:
	return _movable.moved if is_movable else false

func has_sprite() -> bool:
	if _sprite_node != null:
		return true
	else: # confirm
		for child in self.get_children():
			if child is AnimatedSprite2D or child is Sprite2D:
				return true
		return false

# Return the sprite node
func get_sprite() -> Node:
	if _sprite_node == null:
		for child in self.get_children():
			if child is AnimatedSprite2D or child is Sprite2D:
				_sprite_node = child
	if _sprite_node == null:
		escoria.logger.error(
			self,
			"No sprite node found in the scene %s." % get_path()
		)
	return _sprite_node


# Set the angle
#
# #### Parameters
#
# - deg: The angle degree to set
# - wait: Wait this amount of seconds until continuing with turning around
func set_angle(deg: int, wait: float = 0.0):
	if is_movable:
		_movable.set_angle(deg, wait)
	else:
		escoria.logger.warn(
			self,
			"Node %s cannot use \"set_angle\". Its \"is_movable\" parameter is false." % self
		)


# Set the direction id
#
# #### Parameters
#
# - direction_id: The direction id
# - wait: Wait this amount of seconds until continuing with turning around
func set_direction(direction_id: int, wait: float = 0.0):
	if is_movable:
		_movable.set_direction(direction_id, wait)
	else:
		escoria.logger.warn(
			self,
			"Node %s cannot use \"set_direction\". Its \"is_movable\" parameter is false." % self
		)


# Turn to face another object
#
# #### Parameters
#
# - deg: The angle degree to set
# - float Wait this amount of seconds until continuing with turning around
func turn_to(object: Node, wait: float = 0.0):
	if is_movable:
		_movable.turn_to(object, wait)
	else:
		escoria.logger.warn(
			self,
			"Node %s cannot use \"turn_to\". Its \"is_movable\" parameter is false." % self
		)


# Check everything is in place to play talk animations
func check_talk_possible():
	if is_movable and (_movable.last_dir < 0 \
			or _movable.last_dir >= animations.speaks.size()):
		escoria.logger.warn(
			self,
			"Node %s cannot talk. Its \"last_dir\" parameter is invalid: %s." \
			% [self, _movable.last_dir]
		)
		return false
	if not is_instance_valid(animations):
		escoria.logger.warn(
			self,
			"Node %s cannot talk. Its \"animations\" parameter is empty." \
			% self
		)
		return false
	if animations.speaks.size() == 0:
		escoria.logger.warn(
			self,
			"Node %s cannot talk. Its \"animations.speaks\" array is empty." \
			% self
		)
		return false
	if not get_animation_player():
		escoria.logger.warn(
			self,
			"Node %s cannot talk. Its animation player can't be found." \
			% self
		)
		return false
	return true


# Play the talking animation
func start_talking():
	if not check_talk_possible():
		return

	var animation_player = get_animation_player()

	if animation_player.is_playing():
		animation_player.stop()

	if is_movable and animations.speaks[_movable.last_dir].mirrored \
			and not _movable.is_mirrored:
		_sprite_node.scale.x *= -1

	var animation_direction = _movable.last_dir if is_movable else 0
	animation_player.play(
		animations.speaks[animation_direction].animation
	)


# Stop playing the talking animation
func stop_talking():
	if not check_talk_possible():
		return

	var animation_player = get_animation_player()

	if animation_player.is_playing():
		animation_player.stop()

	if is_movable:
		if animations.speaks[_movable.last_dir].mirrored \
				and not _movable.is_mirrored:
			# Allow this function to be called multiple times without setting
			# the direction incorrectly
			if _sprite_node.scale.x < 1:
				_sprite_node.scale.x *= -1

		animation_player.play(
			animations.idles[_movable.last_dir].animation
		)
	else:
		animation_player.play(
			animations.idles[0].animation
		)

# Replay the last idle animation
func update_idle():
	get_animation_player().play(
		animations.idles[_movable.last_dir].animation
	)


# Return the camera position if a camera_position_node exists or the
# global position of the player
func get_camera_node():
	if has_node(camera_node):
		escoria.logger.debug(
			self,
			"Camera3D node found - directing camera to the camera_node on %s."
				% global_id
		)
		return get_node(camera_node)
	return self


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

	if node_path.is_empty():
		animation_player_node = node_path
		return

	assert(has_node(node_path), "Node with path %s not found" % node_path)
	assert(
		get_node(node_path) is AnimatedSprite2D or \
				get_node(node_path) is AnimationPlayer,
		"Selected node has to be an AnimatedSprite2D or AnimationPlayer node"
	)

	animation_player_node = node_path


# Returns either the set inventory texture or the texture of a TextureRect
# found as a child if it is null
func _get_inventory_texture() -> Texture2D:
	if inventory_texture == null:
		for c in get_children():
			if c is TextureRect or c is Sprite2D:
				return c.texture
		return null
	else:
		return inventory_texture


func _get_inventory_texture_hovered() -> Texture2D:
	if inventory_texture_hovered == null:
		for c in get_children():
			if c is TextureRect or c is Sprite2D:
				return c.texture
		return null
	else:
		return inventory_texture_hovered

# Checks whether the given ESCAnimationResource property array has all non-null entries, and adds
# to the scene's warnings if not.
#
# #### Parameters
#
# - property: ESCAnimationResource property. Must be an array.
# - property_name: the name of the property being passed in.
func _validate_animations_property_all_not_null(property: Array, property_name: String) -> void:
	var has_empty_entry: bool = false

	for item in property:
		if item == null:
			has_empty_entry = true
			break

	if has_empty_entry:
		_scene_warnings.append("At least one entry in '%s' is empty. [%s]" % [property_name, _get_identifier_as_key_value()])


# Returns the global ID as a key/value pair. If none is specified, use the node name.
# Used to tag messages.
func _get_identifier_as_key_value() -> String:
	if self.global_id:
		return "global_id: %s" % self.global_id
	else:
		return "node: %s" % get_name()


func _apply_hover_behavior() -> void:
	if not hover_enabled:
		return
	if has_sprite():
		var sprite = get_sprite()
		_previous_color_modulate = modulate
		sprite.modulate = hover_modulate
		if sprite is Sprite2D:
			if hover_texture != null:
				_previous_texture = sprite.texture
				sprite.texture = hover_texture
			if hover_shader != null:
				sprite.material = hover_shader

func _apply_unhover_behavior() -> void:
	if not hover_enabled:
		return
	if has_sprite():
		var sprite = get_sprite()
		sprite.modulate = _previous_color_modulate
		if sprite is Sprite2D:
			if hover_texture != null:
				sprite.texture = _previous_texture
			if hover_shader != null:
				sprite.material = null

# Whether the item is currently moving.
#
# *Returns*
# Returns true if the player is currently moving, false otherwise
func is_moving() -> bool:
	return _movable.task != ESCMovable.MovableTask.NONE if is_movable else false


func get_directions_quantity() -> int:
	return animations.dir_angles.size()


func get_custom_data() -> Dictionary:
	return custom_data


func set_custom_data(data: Dictionary) -> void:
	custom_data = data if (data != null) else {}
