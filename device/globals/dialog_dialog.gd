extends Control

const COLOR_MOUSE_ENTER_FONT = Color(1,1,0.3)
const COLOR_MOUSE_ENTER_FONT_SHADOW = Color(0.6,0.4,0)
const COLOR_MOUSE_EXIT_FONT = Color(1,1,1)
const COLOR_MOUSE_EXIT_FONT_SHADOW = Color(1,1,1)

var vm
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

func start(params, p_context):
	#stop()
	printt("dialog start with params ", params.size())
	context = p_context
	cmd = params[0]
	var i = 0
	var visible = 0
	for q in cmd:
		if !vm.test(q):
			i+=1
			continue
		var it = item.duplicate()
		var but = it.get_node("button")
		var label = but.get_node("label")

		var force_ids = Globals.get("debug/force_text_ids")
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
		but.connect("mouse_enter",self,"_on_mouse_enter",[but])
		but.connect("mouse_exit",self,"_on_mouse_exit",[but])

		var height_ratio = Globals.get("platform/dialog_option_height")
		var size = it.get_custom_minimum_size()
		size.y = size.y * height_ratio
		it.set_custom_minimum_size(size)


		container.add_child(it)
		if i == 0:
			but.grab_focus()
		i+=1
		visible += 1

	if has_node("avatars"):
		var avatar = "default"
		if params.size() >= 3:
			avatar = params[2]
		var avatars = get_node("avatars")
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
	
func _on_mouse_enter(button):
	button.get_node("label").add_color_override("font_color",COLOR_MOUSE_ENTER_FONT)
	button.get_node("label").add_color_override("font_color_shadow",COLOR_MOUSE_ENTER_FONT_SHADOW)
	
func _on_mouse_exit(button):
	button.get_node("label").add_color_override("font_color",COLOR_MOUSE_EXIT_FONT)
	button.get_node("label").add_color_override("font_color_shadow",COLOR_MOUSE_EXIT_FONT_SHADOW)

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

func anim_finished():
	var cur = animation.get_current_animation()
	if cur == "show":
		ready = true
		if timer_timeout > 0:
			timer.start()
			if animation.has_animation("timer"):
				animation.set_current_animation("timer")
				var len = animation.get_current_animation_length()
				animation.set_speed(len / timer_timeout)
				animation.play()

	if cur == "hide":
		vm.finished(context)
		vm.add_level(cmd[option_selected].params[1], false)
		stop()

func _ready():

	printt("dialog ready")
	hide()
	vm = get_tree().get_root().get_node("vm")
	container = get_node("anchor/scroll/container")
	container.set_stop_mouse(false)
	#add_to_group("dialog_dialog")
	item = get_node("item")
	item.get_node("button/label").set_stop_mouse(false)
	item.get_node("button").set_stop_mouse(false)
	item.set_stop_mouse(false)
	call_deferred("remove_child", item)
	animation = get_node("animation")
	animation.connect("finished", self, "anim_finished")
	#get_node("anchor/scroll").set_theme(preload("res://game/globals/dialog_theme.xml"))
	add_to_group("game")
