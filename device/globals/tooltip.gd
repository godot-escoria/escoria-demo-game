extends Label

var force_hide_tooltip = false  # Used by `set_tooltip_visible` to never show

var orig_size

func show():
	if force_hide_tooltip:
		return

	if not self.text:
		var errors = ["Trying to show empty tooltip"]

		if vm.overlapped_obj:
			errors.push_back("Overlapped object: " + vm.overlapped_obj.global_id)

		if vm.hover_obj:
			errors.push_back("Hovered object: " + vm.hover_obj.global_id)

		vm.report_errors("tooltip", errors)

	set_tooltip_visible(true)

func hide():
	# Although we try to hide implicit magick, there's no point in having text pending there
	self.text = ""

	set_tooltip_visible(false)

func set_tooltip(text):
	if not typeof(text) == TYPE_STRING:
		vm.report_errors("tooltip", ["Trying to set tooltip of type: " + str(typeof(text))])

	if force_hide_tooltip:
		# vm.reset_overlapped_obj()
		if self.visible:
			vm.report_errors("tooltip", ["Forcibly hidden tooltip visible while trying to set text: " + text])
		return

	self.text = text
	self.rect_size = orig_size

func set_tooltip_visible(p_visible):
	self.visible = p_visible and self.text and not force_hide_tooltip

func force_tooltip_visible(p_force_hide_tooltip):
	# Not visible (false) means it's hidden
	force_hide_tooltip = not p_force_hide_tooltip
	printt("force-hide tooltip:", force_hide_tooltip)
	if force_hide_tooltip:
		self.hide()

func set_visible(p_visible):
	visible = p_visible

func _clamp(tt_pos):
	var width = float(ProjectSettings.get("display/window/size/width"))
	var height = float(ProjectSettings.get("display/window/size/height"))
	var tt_size = self.get_size()
	var center_offset = tt_size.x / 2

	# We want to have the center of the tooltip above where the cursor is, compensate first
	tt_pos.x -= center_offset  # Shift it half-way to the left
	tt_pos.y -= tt_size.y  # Shift it one size up

	var dist_from_right = width - (tt_pos.x + tt_size.x)  # Check if the right edge, not eg. center, is overflowing
	var dist_from_left = tt_pos.x
	var dist_from_bottom = height - (tt_pos.y + tt_size.y)
	var dist_from_top = tt_pos.y

	## XXX: Godot has serious issues with the width of the text, so tooltips need
	## to be wide at a fixed size, which makes clamping a bit weird.
	## The code is left here in case someone fixes Godot.
	if dist_from_right < 0:
		tt_pos.x += dist_from_right
	if dist_from_left < 0:
		tt_pos.x -= dist_from_left
	if dist_from_bottom < 0:
		tt_pos.y += dist_from_bottom
	if dist_from_top < 0:
		tt_pos.y -= dist_from_top

	return tt_pos

func set_position(pos):
	.set_position(_clamp(pos))

func _ready():
	vm.register_tooltip(self)
	orig_size = self.rect_size

