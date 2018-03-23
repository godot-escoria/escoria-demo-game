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

func check_clamp(click_pos, camera):
	var my_size = get_size()
	var vp_size = get_viewport().size

	var dist_from_right = vp_size.x - (click_pos.x + my_size.x)
	var dist_from_left = click_pos.x - my_size.x
	var dist_from_bottom = vp_size.y - (click_pos.y + my_size.y)
	var dist_from_top = click_pos.y - my_size.y

	if dist_from_right < 0:
		click_pos.x += dist_from_right
	if dist_from_left < 0:
		click_pos.x -= dist_from_left
	if dist_from_bottom < 0:
		click_pos.y += dist_from_bottom
	if dist_from_top < 0:
		click_pos.y -= dist_from_top

	return click_pos - get_size()

func start(p_target):
	if target != p_target:
		target = p_target
		target.connect("visibility_changed", self, "target_visibility_changed")

		# Do not display the tooltip alongside the menu
		if ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse"):
			get_tree().call_group("hud", "hide")

	var scale = ProjectSettings.get_setting("escoria/platform/action_menu_scale")
	set_scale(Vector2(scale, scale))

func stop():
	if target != null:
		target.disconnect("visibility_changed", self, "target_visibility_changed")
	target = null
	hide()
	if ProjectSettings.get_setting("escoria/ui/tooltip_follows_mouse"):
		get_tree().call_group("hud", "show")

func _ready():

	var acts = get_node("actions")
	for i in range(acts.get_child_count()):
		var c = acts.get_child(i)
		if !(c is BaseButton):
			continue
		c.connect("pressed", self, "action_pressed", [c.get_name()])

