extends Control 

var target = null
var slot = ""
var anim

func start(message, p_target, p_slot):
	if has_node("message"):
		$"message".set_text(message)
	else:
		# This allows having TextureRects by the name of eg UI_CONFIRM_NEW_GAME or UI_CONFIRM_QUIT
		get_node(message).show()
	target = p_target
	slot = p_slot
	anim.play("open")
	main.menu_open(self)
	show()

func button_pressed(p_confirm):
	printt("button pressed!", p_confirm, anim.is_playing())
	if anim.is_playing():
		return
	if target != null:
		target.call_deferred(slot, p_confirm)
	close()

func menu_collapsed():
	close()


func close():
	main.menu_close(self)
	if anim.is_playing():
		var cur = anim.get_current_animation()
		if cur == "close":
			return

	anim.play("close")

func anim_finished(anim_name):
	if anim_name == "close":
		queue_free()

func input(event):
	if anim.is_playing():
		return
	if event.is_action("menu_request") && event.is_pressed() && !event.is_echo():
		button_pressed(false)

func _ready():
	get_node("yes").connect("pressed", self, "button_pressed", [true])
	get_node("no").connect("pressed", self, "button_pressed", [false])
	anim = get_node("animation")
	anim.connect("animation_finished", self, "anim_finished")
