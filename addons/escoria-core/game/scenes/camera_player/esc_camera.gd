# Camera handling
extends Camera2D
class_name ESCCamera


# Reference to the tween node for animating camera movements
onready var tween = $"tween"

# Target position of the camera
var target: Vector2 = Vector2()

# The object to follow
var follow_target: Node = null

# Target zoom of the camera
var zoom_target: Vector2

var zoom_time


# This is needed to adjust dialog positions and such, see dialog_instance.gd
var zoom_transform


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


func _resolve_target_and_zoom(p_target) -> void:
	target = Vector2()
	zoom_target = Vector2()
	follow_target = null
	if p_target is Vector2:
		target = p_target
	elif p_target is Array:
		var target_pos = Vector2()

		for obj in p_target:
			target_pos += obj.get_camera_pos()

		# Let the error in if an empty array was passed (divzero)
		target = target_pos / p_target.size()
	elif p_target is Node and p_target.has_node("camera_pos") and \
			p_target.get_node("camera_pos") is Camera2D:
		target = p_target.get_node("camera_pos").global_position
		zoom_target = p_target.get_node("camera_pos").zoom
	elif p_target is Node and "is_movable" in p_target and p_target.is_movable:
		follow_target = p_target
	elif p_target.has_method("get_camera_pos"):
		target = p_target.get_camera_pos()
	else:
		target = p_target.global_position


func set_drag_margin_enabled(p_dm_h_enabled, p_dm_v_enabled):
	self.drag_margin_h_enabled = p_dm_h_enabled
	self.drag_margin_v_enabled = p_dm_v_enabled


func set_target(p_target, p_speed : float = 0.0):
	var speed = p_speed
	
	_resolve_target_and_zoom(p_target)
	
	if not follow_target == null:
		target = follow_target.global_position
	
	escoria.logger.info("Current camera position = " + str(self.global_position))

	if speed == 0.0:
		self.global_position = target
	else:
		var time = self.global_position.distance_to(target) / speed

		if tween.is_active():
			var tweenstat = String(tween.tell()) + "/" + String(tween.get_runtime())
			escoria.logger.report_warnings("camera.gd:set_target()", 
				["Tween still active running camera_set_target: " + tweenstat])
			tween.emit_signal("tween_completed")

		tween.interpolate_property(
			self, 
			"global_position", 
			self.global_position, 
			target, 
			time, 
			Tween.TRANS_LINEAR, 
			Tween.EASE_IN_OUT
		)
		tween.start()

func set_camera_zoom(p_zoom_level, p_time):
	if p_zoom_level <= 0.0:
		escoria.logger.report_errors("camera.gd:set_camera_zoom()", 
			["Tried to set negative or zero zoom level"])

	zoom_time = p_time
	zoom_target = Vector2(1, 1) * p_zoom_level

	if zoom_time == 0:
		self.zoom = zoom_target
	else:
		if tween.is_active():
			var tweenstat = String(tween.tell()) + "/" + String(tween.get_runtime())
			escoria.logger.report_warnings("camera", 
				["Tween still active running camera_set_zoom: " + tweenstat])
			tween.emit_signal("tween_completed")

		tween.interpolate_property(self, "zoom", self.zoom, zoom_target, 
			zoom_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()


func push(p_target, p_time, p_type):
	var time = float(p_time)
	var type = "TRANS_" + p_type

	_resolve_target_and_zoom(p_target)
	
	var push_target = null
	
	if follow_target != null:
		push_target = p_target.position
	else:
		push_target = target

	if time == 0:
		self.global_position = push_target
		if zoom_target != Vector2():
			self.zoom = zoom_target
	else:
		if tween.is_active():
			var tweenstat = String(tween.tell()) + "/" + String(tween.get_runtime())
			escoria.logger.report_warnings("camera", 
				["Tween still active running camera_push: " + tweenstat])
			tween.emit_signal("tween_completed", null, null)

		if zoom_target != Vector2():
			tween.interpolate_property(
				self, 
				"zoom", 
				self.zoom, 
				zoom_target, 
				time, 
				tween.get(type), 
				Tween.EASE_IN_OUT
			)

		tween.interpolate_property(
			self, 
			"global_position", 
			self.global_position, 
			push_target, 
			time, 
			tween.get(type),
			Tween.EASE_IN_OUT
		)
		
		tween.start()


func shift(p_x, p_y, p_time, p_type):
	follow_target = null
	var x = int(p_x)
	var y = int(p_y)
	var time = float(p_time)
	var type = "TRANS_" + p_type

	var new_pos = self.global_position + Vector2(x, y)
	target = new_pos

	if tween.is_active():
		var tweenstat = String(tween.tell()) + "/" + String(tween.get_runtime())
		escoria.logger.report_warnings("camera", 
			["Tween still active running camera_shift: " + tweenstat])
		tween.emit_signal("tween_completed")
	
	tween.interpolate_property(self, "global_position", self.global_position, 
		new_pos, float(time), tween.get(type), Tween.EASE_IN_OUT)
	tween.start()


func target_reached():
	tween.stop_all()

func _process(_delta):
	zoom_transform = self.get_canvas_transform()

	if follow_target and not tween.is_active() and follow_target.has_moved():
		self.global_position = follow_target.global_position

func _ready():
	tween.connect("tween_all_completed", self, "target_reached")
	escoria.object_manager.register_object(
		ESCObject.new(
			self.name,
			self
		),
		true
	)

