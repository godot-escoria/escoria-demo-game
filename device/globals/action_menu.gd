extends Container

var target
func action_pressed(action):
	if !is_visible():
		return
	if !get_node("/root/vm").can_interact():
		return

	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "action_menu_selected", target, action)

func target_visibility_changed():
	stop()

func _clamp(click_pos):
	var scale = ProjectSettings.get_setting("escoria/platform/action_menu_scale")
	set_scale(Vector2(scale, scale))

	var width = float(ProjectSettings.get("display/window/size/width"))
	var height = float(ProjectSettings.get("display/window/size/height"))
	var my_size = get_size() * Vector2(scale, scale)
	var center_offset = my_size / Vector2(2, 2)  # Half to the left, half up

	# Set the action menu in the middle
	click_pos -= center_offset

	var dist_from_right = width - (click_pos.x + my_size.x)
	var dist_from_left = click_pos.x
	var dist_from_bottom = height - (click_pos.y + my_size.y)
	var dist_from_top = click_pos.y

	if dist_from_right < 0:
		click_pos.x += dist_from_right
	if dist_from_left < 0:
		click_pos.x -= dist_from_left
	if dist_from_bottom < 0:
		click_pos.y += dist_from_bottom
	if dist_from_top < 0:
		click_pos.y -= dist_from_top

	return click_pos

func start(p_target):
	if target != p_target:
		target = p_target
		target.connect("visibility_changed", self, "target_visibility_changed")

		# Do not display the tooltip alongside the menu
		if vm.tooltip and ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse"):
			vm.tooltip.hide()  # XXX: Maybe the tooltip should hide itself automatically if the action menu is visible
			vm.hover_teardown()

func stop(show_tooltip=true):
	if target != null:
		target.disconnect("visibility_changed", self, "target_visibility_changed")
	target = null
	hide()
	if vm.tooltip and ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse") and show_tooltip:
		vm.hover_rebuild()

func set_menu_position(pos):
	.set_position(_clamp(pos))

func _ready():
	var acts = get_node("actions")

	for i in range(acts.get_child_count()):
		var c = acts.get_child(i)
		if !(c is BaseButton):
			continue
		c.connect("pressed", self, "action_pressed", [c.get_name()])

	vm.register_action_menu(self)

