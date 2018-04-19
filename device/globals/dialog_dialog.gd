extends Control

export var mouse_enter_color = Color(1,1,0.3)
export var mouse_enter_shadow_color = Color(0.6,0.4,0)
export var mouse_exit_color = Color(1,1,1)
export var mouse_exit_shadow_color = Color(1,1,1)

var cmd
var container
var context
var item
var animation
var ready = false
var option_selected
var timer
var timer_timeout = 0
var timeout_option = 0

func selected(n):
	if !ready:
		return
	option_selected = n
	animation.play("hide")
	ready = false
	if timer != null:
		timer.stop()
		animation.set_speed(1)

func timer_timeout():
	selected(timeout_option)

# called from global_vm.gd::dialog() function
func start(params, p_context):
	#stop()
	printt("dialog start with params ", params.size())
	context = p_context
	cmd = params[0]
	var i = 0
	var nb_visible = 0
	for q in cmd:
		if !vm.test(q):
			i+=1
			continue
		var it = item.duplicate()
		var but = it.get_node("button")
		var label = but.get_node("label")

		var force_ids = ProjectSettings.get_setting("escoria/platform/force_text_ids")
		var text = q.params[0]
		var sep = text.find(":\"")
		if sep > 0:
			var tid = text.substr(0, sep)
			text = text.substr(sep + 2, text.length() - (sep + 2))

			var ptext = TranslationServer.translate(tid)
			if ptext != tid:
				text = ptext
			elif force_ids:
				text = tid + " (" + text + ")"

		elif force_ids:
			text = "(no id) " + text

		label.set_text(text)
		but.connect("pressed", self, "selected", [i])
		but.connect("mouse_entered",self,"_on_mouse_enter",[but])
		but.connect("mouse_exited",self,"_on_mouse_exit",[but])

		var height_ratio = ProjectSettings.get_setting("escoria/platform/dialog_option_height")
		var size = it.get_custom_minimum_size()
		size.y = size.y * height_ratio
		it.set_custom_minimum_size(size)


		container.add_child(it)
		if i == 0:
			but.grab_focus()
		i+=1
		nb_visible += 1

		_on_mouse_exit(but)

	if has_node("anchor/avatars"):
		var avatar = "default"
		if params.size() >= 3:
			avatar = params[2]
		var avatars = get_node("anchor/avatars")
		for i in range(avatars.get_child_count()):
			var c = avatars.get_child(i)
			if c.get_name() == avatar:
				c.show()
			else:
				c.hide()

	timer_timeout = 0
	timeout_option = 0
	if params.size() >= 4:
		timer_timeout = float(params[3])
		if params.size() >= 5:
			timeout_option = int(params[4])

	if timer_timeout > 0:
		printt("********* dialog has timeout", timer_timeout, timeout_option)
		timer = Timer.new()
		add_child(timer)
		timer.set_one_shot(true)
		timer.set_wait_time(timer_timeout)
		timer.connect("timeout", self, "timer_timeout")
		#timer.start()

	ready = false
	animation.play("show")
	animation.seek(0, true)

func _on_mouse_enter(button):
	button.get_node("label").add_color_override("font_color", mouse_enter_color)
	button.get_node("label").add_color_override("font_color_shadow", mouse_enter_shadow_color)

func _on_mouse_exit(button):
	button.get_node("label").add_color_override("font_color", mouse_exit_color)
	button.get_node("label").add_color_override("font_color_shadow", mouse_exit_shadow_color)

func stop():
	hide()
	while container.get_child_count() > 0:
		var c = container.get_child(0)
		container.remove_child(c)
		c.free()
	vm.request_autosave()
	queue_free()

func game_cleared():
	queue_free()

func anim_finished(anim_name):
	if anim_name == "show":
		ready = true
		if timer_timeout > 0:
			timer.start()
			if animation.has_animation("timer"):
				animation.set_current_animation("timer")
				var length = animation.get_current_animation_length()
				animation.set_speed(length / timer_timeout)
				animation.play()

	if anim_name == "hide":
		vm.finished(context)
		vm.add_level(cmd[option_selected].params[1], false)
		stop()

func _ready():
	printt("dialog ready")
	hide()
	container = get_node("anchor/scroll/container")
	container.set_mouse_filter(MOUSE_FILTER_PASS)
	add_to_group("dialog_dialog")
	item = get_node("item")
	item.get_node("button/label").set_mouse_filter(MOUSE_FILTER_PASS)
	item.get_node("button").set_mouse_filter(MOUSE_FILTER_PASS)
	item.set_mouse_filter(MOUSE_FILTER_PASS)
	call_deferred("remove_child", item)
	animation = get_node("animation")
	animation.connect("animation_finished", self, "anim_finished")
	#get_node("anchor/scroll").set_theme(preload("res://demo/globals/dialog_theme.xml"))
	add_to_group("game")
