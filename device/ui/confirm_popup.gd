extends Control

var lang_node
var target = null
var slot = ""
var confirm
var anim

func start(p_node, p_target, p_slot):
	target = p_target
	slot = p_slot

	# This allows having TextureRects by the name of eg UI_CONFIRM_NEW_GAME or UI_CONFIRM_QUIT
	lang_node.get_node(p_node).show()

	if anim:
		anim.play("open")

	main.menu_open(self)
	show()

func button_pressed(p_confirm):
	# This must be global or else we might see an animated confirmation menu
	# overlaid onto the scene when starting a new game. See `anim_finished`.
	confirm = p_confirm

	printt("button pressed!", slot, target.name, confirm)
	if anim and anim.is_playing():
		printt("anim is playing!", anim.current_animation)
		return

	# `anim_finished` calls target, but call it now if there are no animations
	if not anim:
		target.call_deferred(slot, confirm)

	close()

func menu_collapsed():
	close()

func close():
	main.menu_close(self)
	if anim and anim.is_playing():
		printt("close: anim is playing!", anim.current_animation)
		if anim.current_animation == "close":
			return

	elif anim:
		# Once this is finished, `anim_finished` will call `queue_free()`
		# and whatever is defined in the target
		anim.play("close")
	else:
		queue_free()

func anim_finished(anim_name):
	# print("Finished anim ", anim_name)
	if anim_name == "close":
		target.call_deferred(slot, confirm)
		queue_free()

func input(event):
	if anim and anim.is_playing():
		return
	if event.is_action("menu_request") && event.is_pressed() && !event.is_echo():
		button_pressed(false)

func _ready():
	var lang = TranslationServer.get_locale()

	if not has_node(lang) and "_" in lang:
		lang = lang.split("_")[0]

	lang_node = get_node(lang)
	if not lang_node:
		vm.report_errors("confirm_popup",
						 ["No language node " + TranslationServer.get_locale() + " in confirmation popup"])

	lang_node.get_node("yes").connect("pressed", self, "button_pressed", [true])
	lang_node.get_node("no").connect("pressed", self, "button_pressed", [false])

	if has_node("animation"):
		anim = $"animation"
		anim.connect("animation_finished", self, "anim_finished")

