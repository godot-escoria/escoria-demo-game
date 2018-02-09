var target
var actions

func action_pressed(action):
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "action_menu_selected", target, action)

func target_visibility_changed():
	stop()

func start(p_target):
	#actions[0].grab_focus()

	if target != p_target:
		target = p_target
		target.connect("visibility_changed", self, "target_visibility_changed")

	var scale = ProjectSettings.get("platform/action_menu_scale")
	set_scale(Vector2(scale, scale))

func stop():
	if target != null:
		target.disconnect("visibility_changed", self, "target_visibility_changed")
	target = null
	hide()

func _input(event):
	if !is_visible():
		return
	if !get_node("/root/vm").can_interact():
		return
	if !event.is_pressed():
		return

	for a in actions:
		if event.is_action(a.get_name()):
			action_pressed(a.get_name())
			break

func _ready():

	actions = []
	var acts = get_node("actions")
	for i in range(acts.get_child_count()):
		var c = acts.get_child(i)
		if !c.is_type("Button"):
			continue
		actions.push_back(c)
		c.connect("pressed", self, "action_pressed", [c.get_name()])

	set_process_input(true)
