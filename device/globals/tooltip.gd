extends Label

var follow_mouse = ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse")
var width = float(ProjectSettings.get("display/window/size/width"))
var height = float(ProjectSettings.get("display/window/size/height"))

var highlight_only = false      # Is this tooltip used only for highlighting?
var force_hide_tooltip = false  # Used by `set_tooltip_visible` to never show

var orig_size

func show():
	set_process_input(true)

	if force_hide_tooltip:
		return

	if not self.text:
		var errors = ["Trying to show empty tooltip"]

		if vm.hover_object:
			errors.push_back("Hovered object: " + vm.hover_object.global_id)

		vm.report_errors("tooltip", errors)

	set_tooltip_visible(true)

func hide():
	# Although we try to hide implicit magick, there's no point in having text pending there
	self.text = ""

	set_tooltip_visible(false)

	set_process_input(false)

func update():
	if vm.action_menu and vm.action_menu.visible:
		return

	var text = ""

	if vm.hover_object:
		var tt
		var is_actionable = vm.hover_object is esc_type.ITEM or vm.hover_object is esc_type.NPC

		if vm.current_action and vm.current_tool and vm.current_tool != vm.hover_object and is_actionable:
			if not "inventory" in vm.hover_object or not vm.hover_object.inventory:
				if not vm.inventory or not vm.inventory.blocks_tooltip():
					text = tr(vm.current_action + ".combine_id")
					text = text.replace("%2", tr(vm.hover_object.get_tooltip("object2")))
					text = text.replace("%1", tr(vm.current_tool.get_tooltip("object1")))
				else:
					text = tr("use.id")
					text = text.replace("%1", tr(vm.current_tool.get_tooltip("object1")))
			else:
					text = tr(vm.current_action + ".combine_id")
					text = text.replace("%2", tr(vm.hover_object.get_tooltip("object2")))
					text = text.replace("%1", tr(vm.current_tool.get_tooltip("object1")))
		elif vm.current_action == "use" and vm.current_tool:
			text = tr("use.id")
			text = text.replace("%1", tr(vm.current_tool.get_tooltip("object1")))
		else:
			tt = vm.hover_object.get_tooltip()
			if not "inventory" in vm.hover_object or not vm.hover_object.inventory:
				if not vm.inventory or not vm.inventory.blocks_tooltip():
					text = tr(tt)
			else:
					text = tr(tt)
	else:
		if vm.current_action and vm.current_tool:
			if not vm.hover_object:
				text = tr(vm.current_action + ".id")
				text = text.replace("%1", tr(vm.current_tool.get_tooltip("object1")))

	set_tooltip(text)
	if text:
		show()
		if follow_mouse:
			var mouse_pos = get_tree().get_root().get_viewport().get_mouse_position()
			set_position( mouse_pos)
	else:
		hide()

func set_tooltip(text):
	if not typeof(text) == TYPE_STRING:
		vm.report_errors("tooltip", ["Trying to set tooltip of type: " + str(typeof(text))])

	if force_hide_tooltip:
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
	rect_global_position= _clamp(pos)

func _input(ev):
	if follow_mouse:
		# Must verify `position` is there, key inputs do not have it
		if "position" in ev:
			self.set_position(ev.position)

func _ready():
	orig_size = self.rect_size

	if not highlight_only:
		vm.register_tooltip(self)

	set_process_input(false)