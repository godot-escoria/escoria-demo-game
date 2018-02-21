extends Node2D

var target
func action_pressed(action):
	if !is_visible():
		return
	if !get_node("/root/vm").can_interact():
		return

	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "action_menu_selected", target, action)

func target_visibility_changed():
	stop()

func start(p_target):
	if target != p_target:
		target = p_target
		target.connect("visibility_changed", self, "target_visibility_changed")

	var scale = ProjectSettings.get_setting("escoria/platform/action_menu_scale")
	set_scale(Vector2(scale, scale))

func stop():
	if target != null:
		target.disconnect("visibility_changed", self, "target_visibility_changed")
	target = null
	hide()

func _ready():

	var acts = get_node("actions")
	for i in range(acts.get_child_count()):
		var c = acts.get_child(i)
		if !(c is BaseButton):
			continue
		c.connect("pressed", self, "action_pressed", [c.get_name()])

