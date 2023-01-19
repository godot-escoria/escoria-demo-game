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


# Group for ESCItem's that can be collided with in a scene. Used for quick
# retrieval of such nodes to easily change their attributes at the same time.
const GROUP_ITEM_CAN_COLLIDE = "item_can_collide"


# The global ID of this item
export(String) var global_id

# The ESC script for this item
export(String, FILE, "*.esc") var esc_script

# If true, the ESC script may have an ``:exit_scene`` event to manage scene changes.
# For simple exits that do not require scripted actions, the ``ESCExit`` node may be
# preferred.
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

# Whether this item is movable. A movable item will be scaled with the terrain
# and be moved with commands like teleport and turn_to.
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
export(PoolStringArray) var combine_when_selected_action_is_in = []

# If true, combination must be done in the way it is written in ESC script
# ie. :use ON_ITEM
# If false, combination will be tried in the other way.
export(bool) var combine_is_one_way = false

# If true, then the object must have been picked up before using it.
# A false value is useful for items in the background, such as buttons.
export(bool) var use_from_inventory_only = false

# The visual representation for this item when its in the inventory
export(Texture) var inventory_texture: Texture = null \
		setget ,_get_inventory_texture

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

# The node that references the camera position and zoom if this item is used
# as a camera target
export(NodePath) var camera_node


# ESCAnimationsResource (for walking, idling...)
var animations: ESCAnimationResource setget set_animations

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
var _scene_warnings: PoolStringArray = []


# Add the movable node, connect signals, detect child nodes
# and register this item
func _ready():
	self.pause_mode = Node.PAUSE_MODE_STOP

	_detect_children()

	# We add ourselves to this group so we can easily get a reference to all
	# items in a scene tree.
	add_to_group(GROUP_ITEM_CAN_COLLIDE)

	validate_animations(animations)

	if not self.is_connected("input_event", self, "_on_input_event"):
		connect("input_event", self, "_on_input_event")
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
			null,
			_force_registration
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
		if (not is_exit or dont_apply_terrain_scaling) and is_movable:
			_movable.last_scale = scale
			_movable.update_terrain()


# Mouse exited happens on any item that mouse cursor exited, even those UNDER
# the top level of overlapping stack.
func _on_mouse_exited():
	if escoria.inputs_manager.hover_stack.has(self):
		escoria.inputs_manager.hover_stack_erase_item(self)
	escoria.inputs_manager.unset_hovered_node(self)


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
		var physics2d_dss: Physics2DDirectSpaceState = get_world_2d().direct_space_state
		var colliding: Array = physics2d_dss.intersect_point(get_global_mouse_position(), 32, [], 0x7FFFFFFF, true, true)		
		var colliding_nodes = []
		for c in colliding:
			if c.collider.get("global_id") \
					and escoria.action_manager.is_object_actionable(c.collider.global_id):
				colliding_nodes.push_back(c.collider)

		if colliding_nodes.empty():
			return
		colliding_nodes.sort_custom(HoverStackSorter, "sort_ascending_z_index")
		escoria.inputs_manager.hover_stack_clear()
		escoria.inputs_manager.hover_stack_add_items(colliding_nodes)
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
		event.button_index = BUTTON_LEFT
		event.doubleclick = false
		event.pressed = true
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
			if event.doubleclick and event.button_index == BUTTON_LEFT:
				emit_signal("mouse_double_left_clicked_item", self, event)
				get_tree().set_input_as_handled()
			elif event.button_index == BUTTON_LEFT:
				emit_signal("mouse_left_clicked_item", self, event)
				get_tree().set_input_as_handled()
			elif event.button_index == BUTTON_RIGHT:
				emit_signal("mouse_right_clicked_item", self, event)
				get_tree().set_input_as_handled()


# To display warnings in the scene tree should there be any.
func _get_configuration_warning():
	validate_animations(animations)
	return _scene_warnings.join("\n")


func _is_in_shape(position: Vector2) -> bool:
	var colliders = get_world_2d().direct_space_state.intersect_point(
		position,
		32,
		[],
		2147483647,
		true,
		true
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
		update_configuration_warning()
	elif _scene_warnings.size() > 0:
		escoria.logger.error(
			self,
			_scene_warnings.join(", ")
		)


# Setter for the animations property.
func set_animations(p_animations: ESCAnimationResource) -> void:
	if p_animations == null:
		return

	animations = p_animations

	if not animations.is_connected("changed", self, "_validate_animations"):
		animations.connect("changed", self, "_validate_animations")


# Return the animation player node
func get_animation_player() -> Node:
	if _animation_player == null:
		var player_node_path = animation_player_node
		if player_node_path == "":
			for child in self.get_children():
				if child is AnimatedSprite or \
						child is AnimationPlayer:
					player_node_path = child.get_path()
		if player_node_path == "":
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
	var multiple_positions_found = false
	var interact_position = null
	for c in get_children():
		if c is Position2D:
			if interact_position != null:
				multiple_positions_found = true
			interact_position = c.global_position

	if interact_position == null and collision != null:
		interact_position = collision.global_position
		escoria.logger.warn(
			self,
			"No ESCLocation found to walk to for object " +
			"%s. Middle of collision shape will be used." % global_id)

	if multiple_positions_found:
		escoria.logger.warn(
			self,
			"Multiple ESClocations found to walk to for object " +
			"%s. Last one will be used." % global_id)
	return interact_position


# React to the mouse entering the item by emitting the respective signal
func mouse_entered():
	if escoria.action_manager.is_object_actionable(global_id):
		emit_signal("mouse_entered_item", self)


# React to the mouse exiting the item by emitting the respective signal
func mouse_exited():
	emit_signal("mouse_exited_item",  self)


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
# #### Parameters
#
# - body: Other object that has entered the item
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
func set_speed(speed_value: int) -> void:
	speed = speed_value


# Check whether this item moved
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
			"Camera node found - directing camera to the camera_node on %s."
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


# Returns either the set inventory texture or the texture of a TextureRect
# found as a child if it is null
func _get_inventory_texture() -> Texture:
	if inventory_texture == null:
		for c in get_children():
			if c is TextureRect or c is Sprite:
				return c.texture
		return null
	else:
		return inventory_texture


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


# Whether the item is currently moving.
#
# *Returns*
# Returns true if the player is currently moving, false otherwise
func is_moving() -> bool:
	return _movable.task != ESCMovable.MovableTask.NONE if is_movable else false
