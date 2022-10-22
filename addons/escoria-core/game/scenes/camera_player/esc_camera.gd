# Camera handling
extends Camera2D
class_name ESCCamera


enum Compensation {
	NONE,
	ADDED,
	SUBTRACTED
}


# Reference to the tween node for animating camera movements
var _tween: Tween

# Target position of the camera
var _target: Vector2 = Vector2()

# The object to follow
var _follow_target: Node = null

# Target zoom of the camera
var _zoom_target: Vector2

var _global_pos_x_compensation = Compensation.NONE
var _global_pos_y_compensation = Compensation.NONE


# Prepare the tween
func _ready():
	_tween = Tween.new()
	add_child(_tween)
	_tween.connect("tween_all_completed", self, "_target_reached")


func _exit_tree():
	remove_child(_tween)
	if is_instance_valid(_tween):
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
		_target = _clamp_to_limits(_target)
		_target = _compensate_for_drag_margin_relative(_target, true)
		self.global_position = _target
	else:
		if _tween.is_active():
			escoria.logger.warn(
				self,
				"Tween is still active: %f seconds of %f completed." % [
					_tween.tell(),
					_tween.get_runtime()
				]
			)
			_tween.emit_signal("tween_completed")

		set_drag_margin_enabled(false, false)

		_target = _clamp_to_limits(_target)
		_convert_current_global_pos_for_drag_margin()

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
		if _tween.is_active():
			escoria.logger.warn(
				self,
				"Tween is still active: %f/%f" % [
					_tween.tell(),
					_tween.get_runtime()
				]
			)
			_tween.emit_signal("tween_completed")

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
		push_target = _clamp_to_limits(push_target)
		push_target = _compensate_for_drag_margin_relative(push_target, true)
		self.global_position = push_target

		if _zoom_target != Vector2():
			self.zoom = _zoom_target
	else:
		if _tween.is_active():
			escoria.logger.warn(
				self,
				"Tween is still active: %f seconds of %f completed." % [
					_tween.tell(),
					_tween.get_runtime()
				]
			)
			_tween.emit_signal("tween_completed", null, null)

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

		push_target = _clamp_to_limits(push_target)
		_convert_current_global_pos_for_drag_margin()

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

	set_drag_margin_enabled(false, false)

	var new_pos = self.global_position + p_target
	_target = _clamp_to_limits(new_pos)
	_target = _compensate_for_drag_margin_relative(_target)

	if _tween.is_active():
		escoria.logger.warn(
			self,
			"Tween is still active: %f seconds of %f completed." % [
				_tween.tell(),
				_tween.get_runtime()
			]
		)
		_tween.emit_signal("tween_completed")

	_convert_current_global_pos_for_drag_margin()

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


func _target_reached():
	_tween.stop_all()
	set_drag_margin_enabled(true, true)


# Ensures that to_clamp doesn't go outside of the pre-set viewing limits.
func _clamp_to_limits(to_clamp: Vector2) -> Vector2:
	var clamped_value: Vector2 = to_clamp
	var viewport_rect: Rect2 = get_viewport_rect()

	if clamped_value.x < limit_left + viewport_rect.size.x * 0.5:
		clamped_value.x = limit_left + viewport_rect.size.x * 0.5
	elif clamped_value.x > limit_right - viewport_rect.size.x * 0.5:
		clamped_value.x = limit_right - viewport_rect.size.x * 0.5

	if clamped_value.y < limit_top + viewport_rect.size.y * 0.5:
		clamped_value.y = limit_top + viewport_rect.size.y * 0.5
	elif clamped_value.y > limit_bottom - viewport_rect.size.y * 0.5:
		clamped_value.y = limit_bottom - viewport_rect.size.y * 0.5

	return clamped_value


# We have to compensate for rendering calculations Godot does when it renders the camera each frame.
# We do this since drag margins may be enabled and can skew the resulting position as noted above,
# especially given that the anchor mode is DRAG_CENTER.
#
# (See https://github.com/godotengine/godot/blob/3.5/scene/2d/camera_2d.cpp for more details.)
#
# This helps to ensure that when we disable or enable drag margins that the position on the screen
# is maintained without the camera "jumping".
#
# We also note the relative "compensation" if the position is the camera's global_position since
# if we move from drag margins enabled to disabled (or vice versa), we need to know the appropriate
# amount to offset the original compensation. This is due to Godot's own Camera2D calculations when
# rendering the screen/camera (again, see the link above).
#
# This is something of a hack until we decide on whether we implement an Escoria-specific camera
# instead of relying on Camera2D.
func _compensate_for_drag_margin_relative(p_position: Vector2, for_global_pos: bool = false) -> Vector2:
	var ret_position: Vector2 = p_position
	var viewport_rect: Rect2 = get_viewport_rect()

	if drag_margin_h_enabled:
		if ret_position.x < self.global_position.x:
			ret_position.x = ret_position.x - viewport_rect.size.x * 0.5 * zoom.x * drag_margin_left
			
			if for_global_pos:
				_global_pos_x_compensation = Compensation.SUBTRACTED
		else:
			ret_position.x = ret_position.x + viewport_rect.size.x * 0.5 * zoom.x * drag_margin_right

			if for_global_pos:
				_global_pos_x_compensation = Compensation.ADDED
	else:
		if ret_position.x < self.global_position.x:
			ret_position.x = ret_position.x + viewport_rect.size.x * 0.5 * zoom.x * drag_margin_left
			
			if for_global_pos:
				_global_pos_x_compensation = Compensation.ADDED
		else:
			ret_position.x = ret_position.x - viewport_rect.size.x * 0.5 * zoom.x * drag_margin_right

			if for_global_pos:
				_global_pos_x_compensation = Compensation.SUBTRACTED

	if drag_margin_v_enabled:
		if ret_position.y < self.global_position.y:
			ret_position.y = ret_position.y - viewport_rect.size.y * 0.5 * zoom.y * drag_margin_top

			if for_global_pos:
				_global_pos_y_compensation = Compensation.SUBTRACTED
		else:
			ret_position.y = ret_position.y + viewport_rect.size.y * 0.5 * zoom.y * drag_margin_bottom

			if for_global_pos:
				_global_pos_y_compensation = Compensation.ADDED
	else:
		if ret_position.y < self.global_position.y:
			ret_position.y = ret_position.y + viewport_rect.size.y * 0.5 * zoom.y * drag_margin_top

			if for_global_pos:
				_global_pos_y_compensation = Compensation.ADDED
		else:
			ret_position.y = ret_position.y - viewport_rect.size.y * 0.5 * zoom.y * drag_margin_bottom

			if for_global_pos:
				_global_pos_y_compensation = Compensation.SUBTRACTED

	return ret_position


# Use this to compensate the camera's current (read: fixed) global_position when enabling/disabling
# drag margins.
func _convert_current_global_pos_for_drag_margin() -> void:
	var ret_position: Vector2 = self.global_position
	var viewport_rect: Rect2 = get_viewport_rect()

	if drag_margin_h_enabled:
		if _global_pos_x_compensation == Compensation.ADDED:
			ret_position.x = ret_position.x - viewport_rect.size.x * 0.5 * zoom.x * drag_margin_left
		elif _global_pos_x_compensation == Compensation.SUBTRACTED:
			ret_position.x = ret_position.x + viewport_rect.size.x * 0.5 * zoom.x * drag_margin_right
	else:
		if _global_pos_x_compensation == Compensation.ADDED:
			ret_position.x = ret_position.x - viewport_rect.size.x * 0.5 * zoom.x * drag_margin_right
		elif _global_pos_x_compensation == Compensation.SUBTRACTED:
			ret_position.x = ret_position.x + viewport_rect.size.x * 0.5 * zoom.x * drag_margin_left

	if drag_margin_v_enabled:
		if _global_pos_y_compensation == Compensation.ADDED:
			ret_position.y = ret_position.y - viewport_rect.size.y * 0.5 * zoom.y * drag_margin_top
		elif _global_pos_y_compensation == Compensation.SUBTRACTED:
			ret_position.y = ret_position.y + viewport_rect.size.y * 0.5 * zoom.y * drag_margin_bottom
	else:
		if _global_pos_y_compensation == Compensation.ADDED:
			ret_position.y = ret_position.y - viewport_rect.size.y * 0.5 * zoom.y * drag_margin_bottom
		elif _global_pos_y_compensation == Compensation.SUBTRACTED:
			ret_position.y = ret_position.y + viewport_rect.size.y * 0.5 * zoom.y * drag_margin_top

	_global_pos_x_compensation = Compensation.NONE
	_global_pos_y_compensation = Compensation.NONE

	self.global_position = ret_position


