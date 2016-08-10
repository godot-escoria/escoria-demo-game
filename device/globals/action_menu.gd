var target

func action_pressed(action):
	get_tree().call_group(0, "game", "action_menu_selected", target, action)

func target_visibility_changed():
	stop()

func start(p_target):
	get_node("bg/use").grab_focus()

	if target != p_target:
		target = p_target
		target.connect("visibility_changed", self, "target_visibility_changed")

	var scale = Globals.get("platform/action_menu_scale")
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
	if event.is_action("look"):
		action_pressed("look")
	elif event.is_action("use"):
		action_pressed("use")
	elif event.is_action("talk"):
		action_pressed("talk")

func _ready():
	get_node("bg/look").connect("pressed", self, "action_pressed", ["look"])
	get_node("bg/talk").connect("pressed", self, "action_pressed", ["talk"])
	get_node("bg/use").connect("pressed", self, "action_pressed", ["use"])
	set_process_input(true)
