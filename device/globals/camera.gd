extends Camera2D

var speed = 0
var target

var zoom_time
var zoom_target
var zoom_step

# This is needed to adjust dialog positions and such, see dialog_instance.gd
var zoom_transform

func set_target(p_speed, p_target):
	speed = p_speed
	target = p_target

func set_zoom(p_zoom_level, p_time):
	if p_zoom_level <= 0.0:
		vm.report_errors("camera", ["Tried to set negative or zero zoom level"])

	zoom_time = p_time
	zoom_target = Vector2(1, 1) * p_zoom_level

	# Calculate magnitude to zoom per second
	zoom_step = (zoom_target - self.zoom) / zoom_time

func update(time):
	var target_pos

	# Force some kind of target if there is none
	if not target:
		target = vm.get_object("player")
	if not target:
		target = Vector2(0, 0)

	if typeof(target) == TYPE_VECTOR2:
		target_pos = target
	elif typeof(target) == TYPE_ARRAY:
		var count = 0

		for obj in target:
			target_pos += obj.get_camera_pos()
			count += 1

		# Let the error in if an empty array was passed (divzero)
		target_pos = target_pos / count
	else:
		target_pos = target.get_camera_pos()

	# The camera position is set to target when it's about to overstep it,
	# or when it's moved there instantly.
	# Compare the camera and target position until then
	if self.global_position != target_pos:
		var v = target_pos - self.position  # vector to move along
		var step = speed * time      # pixel size of step to move

		# This is where we may overstep or move instantly
		if step > v.length() || speed == 0:
			self.global_position = target_pos
		else:
			target_pos = self.global_position + v.normalized() * step
			self.global_position = target_pos

	if zoom_target:
		var zstep = zoom_step * time
		var diff = self.zoom - zoom_target
		if zstep.length() > diff.length() || zoom_time == 0:
			self.zoom = zoom_target
			zoom_target = null
			zoom_transform = self.get_canvas_transform()
		else:
			self.zoom += zstep
	# Even when not zooming, somehow the clamping of dialog, when the
	# scene is not zoomed, goes awry without this :/
	else:
		zoom_transform = self.get_canvas_transform()

