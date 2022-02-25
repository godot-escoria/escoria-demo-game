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
	escoria.object_manager.register_object(
		ESCObject.new(
			escoria.object_manager.CAMERA,
			self
		),
		true
	)


# Update the position if the followed target is moving
func _process(_delta):
	if is_instance_valid(_follow_target) and not _tween.is_active() and _follow_target.has_moved():
		self.global_position = _follow_target.global_position


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
# - p_speed: Number of seconds for the camera to reach the target
func set_target(p_target, p_speed : float = 0.0):
	var speed = p_speed

	_resolve_target_and_zoom(p_target)

	escoria.logger.info(
		"Current camera position = %s " % str(self.global_position)
	)

	if speed == 0.0:
		self.global_position = _target
	else:
		var time = self.global_position.distance_to(_target) / speed

		if _tween.is_active():
			escoria.logger.report_warnings(
				"esc_camera.gd:set_target()",
				[
					"Tween is still active: %f/%f" % [
						_tween.tell(),
						_tween.get_runtime()
					]
				]
			)
			_tween.emit_signal("tween_completed")

		_tween.interpolate_property(
			self,
			"global_position",
			self.global_position,
			_target,
			time,
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
		escoria.logger.report_errors(
			"esc_camera.gd:set_camera_zoom()",
			["Tried to set negative or zero zoom level"]
		)

	_zoom_target = Vector2(1, 1) * p_zoom_level

	if p_time == 0:
		self.zoom = _zoom_target
	else:
		if _tween.is_active():
			escoria.logger.report_warnings(
				"esc_camera.gd:set_camera_zoom()",
				[
					"Tween is still active: %f/%f" % [
						_tween.tell(),
						_tween.get_runtime()
					]
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
		self.global_position = push_target
		if _zoom_target != Vector2():
			self.zoom = _zoom_target
	else:
		if _tween.is_active():
			escoria.logger.report_warnings(
				"esc_camera.gd:push()",
				[
					"Tween is still active: %f/%f" % [
						_tween.tell(),
						_tween.get_runtime()
					]
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
		escoria.logger.report_warnings(
				"esc_camera.gd:set_camera_zoom()",
				[
					"Tween is still active: %f/%f" % [
						_tween.tell(),
						_tween.get_runtime()
					]
				]
			)
		_tween.emit_signal("tween_completed")

	_tween.interpolate_property(
		self,
		"global_position",
		self.global_position,
		new_pos,
		p_time,
		p_type,
		Tween.EASE_IN_OUT
	)
	_tween.start()


func _target_reached():
	_tween.stop_all()



