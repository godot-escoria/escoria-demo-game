# Camera handling
extends Camera2D
class_name ESCCamera


# Reference to the tween node for animating camera movements
var _tween: Tween

# Target position of the camera
var _target: Vector2 = Vector2()

# The object to follow
var _follow_target: Node = null

# Target zoom of the camera
var _zoom_target: Vector2


# Prepare the tween
func _ready():
	_tween = Tween.new()
	add_child(_tween)
	_tween.connect("tween_all_completed", self, "_target_reached")


func _exit_tree():
	if is_instance_valid(_tween):
		remove_child(_tween)
		_tween.queue_free()


# Update the position if the followed target is moving
func _process(_delta):
	if is_instance_valid(_follow_target) and not _tween.is_active() and _follow_target.has_moved():
		self.global_position = _follow_target.global_position


# Register this camera with the object manager. We do it out here so we can
# work with the camera before it's made active as part of the current scene
# tree.
#
# #### Parameters
#
# - room: The room with which to register the camera.
func register(room = null):
	escoria.object_manager.register_object(
		ESCObject.new(
			escoria.object_manager.CAMERA,
			self
		),
		room,
		true
	)


# Returns the camera's tween.
#
# **Returns** the tween owned by this camera.
func get_tween() -> Tween:
	return _tween


# Sets camera limits so it doesn't go out of the scene
#
# #### Parameters
#
# - limits: The limits to set
func set_limits(limits: ESCCameraLimits):
	self.limit_left = limits.limit_left
	self.limit_right = limits.limit_right
	self.limit_top = limits.limit_top
	self.limit_bottom = limits.limit_bottom


func set_drag_margin_enabled(p_dm_h_enabled, p_dm_v_enabled):
	self.drag_margin_h_enabled = p_dm_h_enabled
	self.drag_margin_v_enabled = p_dm_v_enabled


# Set the target for the camera
#
# #### Parameters
# - p_target: Object to target
# - p_time: Number of seconds for the camera to reach the target
func set_target(p_target, p_time : float = 0.0):
	_resolve_target_and_zoom(p_target)

	escoria.logger.info(
		self,
		"Current camera position = %s." % str(self.global_position)
	)

	if p_time == 0.0:
		self.global_position = _target
	else:
		# Need to wait a frame in order to ensure the screen centre position is
		# recalculated. Also to allow any close-calls with the tween to finish.
		yield(get_tree(), "idle_frame")

		if _tween.is_active():
			escoria.logger.debug(
				self,
				"set_target tween is still active: %f seconds of %f completed." % [
					_tween.tell(),
					_tween.get_runtime()
				]
			)
			_tween.stop_all()

		set_drag_margin_enabled(false, false)

		_convert_current_global_pos_for_disabled_drag_margin()
		_target = _convert_pos_for_disabled_drag_margin(_target)

		_tween.interpolate_property(
			self,
			"global_position",
			self.global_position,
			_target,
			p_time,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN_OUT
		)
		_tween.start()


# Set the camera zoom level
#
# #### Parameters
# - p_zoom_level: Zoom level to set
# - p_time: Number of seconds for the camera to reach the zoom level
func set_camera_zoom(p_zoom_level: float, p_time: float):
	if p_zoom_level <= 0.0:
		escoria.logger.error(
			self,
			"Tried to set negative or zero zoom level."
		)

	_zoom_target = Vector2(1, 1) * p_zoom_level

	if p_time == 0:
		self.zoom = _zoom_target
	else:
		# Need to wait a frame in order to ensure the screen centre position is
		# recalculated. Also to allow any close-calls with the tween to finish.
		yield(get_tree(), "idle_frame")

		if _tween.is_active():
			escoria.logger.debug(
				self,
				"set_camera_zoom tween is still active: %f seconds of %f completed." % [
					_tween.tell(),
					_tween.get_runtime()
				]
			)
			_tween.stop_all()

		set_drag_margin_enabled(false, false)

		_convert_current_global_pos_for_disabled_drag_margin()

		_tween.interpolate_property(
			self,
			"zoom",
			self.zoom,
			_zoom_target,
			p_time,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN_OUT
		)
		_tween.start()


# Push the camera towards the target in terms of position and zoom level
# using a given transition type and time.
# See
# https://docs.godotengine.org/en/stable/classes/class_tween.html#enumerations
#
# #### Parameters
# - p_target: Target to push to
# - p_time: Number of seconds for the transition to take
# - p_type: Tween transition type
func push(p_target, p_time: float = 0.0, p_type: int = 0):
	_resolve_target_and_zoom(p_target)

	var push_target = null

	if _follow_target != null:
		push_target = p_target.position
	else:
		push_target = _target

	if p_time == 0:
		self.global_position = push_target

		if _zoom_target != Vector2():
			self.zoom = _zoom_target
	else:
		# Need to wait a frame in order to ensure the screen centre position is
		# recalculated. Also to allow any close-calls with the tween to finish.
		yield(get_tree(), "idle_frame")

		if _tween.is_active():
			escoria.logger.debug(
				self,
				"camera push tween is still active: %f seconds of %f completed." % [
					_tween.tell(),
					_tween.get_runtime()
				]
			)
			_tween.stop_all()

		if _zoom_target != Vector2():
			_tween.interpolate_property(
				self,
				"zoom",
				self.zoom,
				_zoom_target,
				p_time,
				p_type,
				Tween.EASE_IN_OUT
			)

		set_drag_margin_enabled(false, false)

		_convert_current_global_pos_for_disabled_drag_margin()

		_tween.interpolate_property(
			self,
			"global_position",
			self.global_position,
			push_target,
			p_time,
			p_type,
			Tween.EASE_IN_OUT
		)

		_tween.start()


# Shift the camera by the given vector in a given time and using a specific
# Tween transition type.
#
# See
# https://docs.godotengine.org/en/stable/classes/class_tween.html#enumerations
#
# #### Parameters
# - p_target: Vector to shift the camera by
# - p_time: Number of seconds for the transition to take
# - p_type: Tween transition type
func shift(p_target: Vector2, p_time: float, p_type: int):
	_follow_target = null

	var new_pos = self.global_position + p_target
	_target = new_pos

	if _tween.is_active():
		# Need to wait a frame in order to ensure the screen centre position is
		# recalculated. Also to allow any close-calls with the tween to finish.
		yield(get_tree(), "idle_frame")

		escoria.logger.debug(
			self,
			"camera shift tween is still active: %f seconds of %f completed." % [
				_tween.tell(),
				_tween.get_runtime()
			]
		)
		_tween.stop_all()

	set_drag_margin_enabled(false, false)

	_convert_current_global_pos_for_disabled_drag_margin()

	_tween.interpolate_property(
		self,
		"global_position",
		self.global_position,
		_target,
		p_time,
		p_type,
		Tween.EASE_IN_OUT
	)
	_tween.start()


# Checks whether the given point is contained within the viewport's limits.
# Note that this is different from the camera's limits when using anchor mode
# DRAG_CENTER.
#
# #### Parameters
# - point: Point to be tested against viewport limits.
#
# **Returns** true iff point is inside the calculated viewport's limits (inclusive)
func check_point_is_inside_viewport_limits(point: Vector2) -> bool:
	var viewport_rect: Rect2 = get_viewport_rect()
	var screen_half_size: Vector2 = viewport_rect.size * 0.5

	var limits_to_test: Rect2 = Rect2(
		limit_left + screen_half_size.x,
		limit_top + screen_half_size.y,
		limit_right - limit_left - viewport_rect.size.x + 1,
		limit_bottom - limit_top - viewport_rect.size.y + 1
	)

	return limits_to_test.has_point(point)


# Returns the inclusive minimum and maximum values for the x-component of the current valid viewport.
# Mainly used in any logging messages related to same.
#
# **Returns** the inclusive minimum and maximum values for the x-component of the current valid viewport.
func get_current_valid_viewport_values_x() -> Array:
	var viewport_rect: Rect2 = get_viewport_rect()

	return [limit_left + viewport_rect.size.x * 0.5, limit_right - viewport_rect.size.x * 0.5]


# Returns the inclusive minimum and maximum values for the y-component of the current valid viewport.
# Mainly used in any logging messages related to same.
#
# **Returns* the inclusive minimum and maximum values for the y-component of the current valid viewport.
func get_current_valid_viewport_values_y() -> Array:
	var viewport_rect: Rect2 = get_viewport_rect()

	return [limit_top + viewport_rect.size.y * 0.5, limit_bottom - viewport_rect.size.y * 0.5]


# Returns the camera's current limits as a Rect2.
# Mainly used in any logging messages related to same.
#
# **Returns** the camera's current limits as a Rect2.
func get_camera_limit_rect() -> Rect2:
	return Rect2(limit_left, limit_top, limit_right - limit_left, limit_bottom - limit_top)


# Used when drag margins are enabled. Clamps the camera so it respects the viewport limits inside
# the camera limits.
func clamp_to_viewport_limits() -> void:
	var viewport_rect: Rect2 = get_viewport_rect()

	var cur_camera_pos: Vector2 = self.get_camera_screen_center()
	var ret_position: Vector2 = cur_camera_pos

	if cur_camera_pos.x - viewport_rect.size.x * 0.5 * zoom.x <= limit_left:
		ret_position.x = limit_left + viewport_rect.size.x * 0.5 * zoom.x * (1 + drag_margin_left)
	elif cur_camera_pos.x + viewport_rect.size.x * 0.5 * zoom.x >= limit_right:
		ret_position.x = limit_right - viewport_rect.size.x * 0.5 * zoom.x * (1 + drag_margin_right)

	if cur_camera_pos.y - viewport_rect.size.y * 0.5 * zoom.y <= limit_top:
		ret_position.y = limit_top + viewport_rect.size.y * 0.5 * zoom.y * (1 + drag_margin_top)
	elif cur_camera_pos.y + viewport_rect.size.y * 0.5 * zoom.y >= limit_bottom:
		ret_position.y = limit_bottom - viewport_rect.size.y * 0.5 * zoom.y * (1 + drag_margin_bottom)

	self.global_position = ret_position


func _target_reached():
	_tween.stop_all()
	set_drag_margin_enabled(true, true)


# Use this to compensate the camera's current global_position when disabling drag margins.
#
# (See https://github.com/godotengine/godot/blob/3.5/scene/2d/camera_2d.cpp for more details.)
#
# This helps to ensure that when we disable or enable drag margins that the position on the screen
# is maintained without the camera "jumping".
#
# This is something of a hack until we decide on whether we implement an Escoria-specific camera
# instead of relying on Camera2D.
func _convert_current_global_pos_for_disabled_drag_margin() -> void:
	var cur_camera_pos: Vector2 = self.get_camera_screen_center()
	var ret_position: Vector2 = _convert_pos_for_disabled_drag_margin(cur_camera_pos)

	self.global_position = ret_position


# Converts the given position set with drag margins enabled to the same position when calculated
# with drag margins disabled.
#
# This is helpful for preventing the camera from "jumping" when disabling drag margins, e.g. in
# order to perform some camera translations/tweening.
#
# #### Parameters
# - pos: Position to be converted.
#
# **Returns** the position on the screen that would be the equivalent of `pos` when rendered with
# drag margins disabled.
func _convert_pos_for_disabled_drag_margin(pos: Vector2) -> Vector2:
	var viewport_rect: Rect2 = get_viewport_rect()
	var ret_position: Vector2 = pos

	# If the current calculated centre of the camera/viewport is close enough to the set camera
	# limits (i.e. the centre is upto and including half the viewport's size to the limit being
	# tested), then we make sure the global_position is at the same coordinates since Camera2D will
	# recalculate that position to the exact same position (i.e. no funny math).
	#
	# Otherwise, we set the global_position to be the value that would allow Camera2D to convert it
	# to the value of the current calculated centre. This compensates for the switch when disabling
	# drag margins.
	if ret_position.x - viewport_rect.size.x * 0.5 * zoom.x <= limit_left:
		ret_position.x = limit_left + viewport_rect.size.x * 0.5 * zoom.x
	elif ret_position.x + viewport_rect.size.x * 0.5 * zoom.x >= limit_right:
		ret_position.x = limit_right - viewport_rect.size.x * 0.5 * zoom.x

	if ret_position.y - viewport_rect.size.y * 0.5 * zoom.y <= limit_top:
		ret_position.y = limit_top + viewport_rect.size.y * 0.5 * zoom.y
	elif ret_position.y + viewport_rect.size.y * 0.5 * zoom.y >= limit_bottom:
		ret_position.y = limit_bottom - viewport_rect.size.y * 0.5 * zoom.y

	return ret_position


# Resolve the correct position and zoom of the target object
#
# #### Parameters
# - p_target: The target to resolve
func _resolve_target_and_zoom(p_target) -> void:
	_target = Vector2()
	_zoom_target = Vector2()
	_follow_target = null

	if p_target is Node and "is_movable" in p_target and p_target.is_movable:
		_follow_target = p_target

	if p_target is Vector2:
		_target = p_target
	elif p_target is Array and p_target.size() > 0:
		var target_pos = Vector2()

		for obj in p_target:
			target_pos += obj.get_camera_pos()

		_target = target_pos / p_target.size()
	elif p_target.has_method("get_camera_node"):
		if "global_position" in p_target.get_camera_node():
			_target = p_target.get_camera_node().global_position
		if "zoom" in p_target.get_camera_node():
			_zoom_target = p_target.get_camera_node().zoom
	else:
		_target = p_target.global_position
