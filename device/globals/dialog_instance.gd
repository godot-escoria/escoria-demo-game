extends Container

var context
var text
var elapsed = 0
var total_time
var character
export var typewriter_text = true
export var characters_per_second = 45.0
var force_disable_typewriter_text = ProjectSettings.get_setting("escoria/platform/force_disable_typewriter_text")
var finished = false
var play_intro = true
var play_outro = true
var label
var text_done = false
var text_timeout_seconds = ProjectSettings.get_setting("escoria/application/text_timeout_seconds")

var speech_stream
var speech_player
var speech_suffix
var speech_paused = false

export var fixed_pos = false

func _process(time):
	if finished:
		return

	if force_disable_typewriter_text or !typewriter_text:
		label.set_visible_characters(label.get_total_character_count())
		text_done = true

	elapsed += time

	if !text_done:
		if elapsed >= total_time:
			label.set_visible_characters(label.get_total_character_count())
			text_done = true

			return
		else:
			label.set_visible_characters(text.length() * elapsed / (total_time))
			pass

	if text_done && !vm.settings.skip_dialog:
		finish()

	if elapsed > text_timeout_seconds and (!speech_player or !speech_player.is_playing()):
		finish()

	if vm.settings.skip_dialog && speech_stream != null && !speech_player.is_playing() && text_done:
		finish()

func skipped():
	if finished:
		return
	if elapsed < total_time:
		elapsed = total_time
	else:
		finish()

func finish():
	character.set_speaking(false)
	set_process(false)
	finished = true
	if has_node("animation") && play_outro:
		var anim = get_node("animation")
		if anim.has_animation("hide"):
			anim.play("hide")
	_queue_free()

func init(p_params, p_context, p_intro, p_outro):
	character = vm.get_object(p_params[0])
	context = p_context
	text = p_params[1]
	var force_ids = ProjectSettings.get_setting("escoria/platform/force_text_ids")
	var sep = text.find(":\"")
	var text_id = null
	if sep > 0:
		text_id = text.substr(0, sep)
		text = text.substr(sep + 2, text.length() - (sep + 2))

		if TranslationServer.get_locale() != ProjectSettings.get_setting("escoria/platform/development_lang"):
			var ptext = TranslationServer.translate(text_id)
			if ptext != text_id:
				text = ptext
			else:
				text = "(NOT TRANSLATED)\n\n" + text

	elif force_ids:
		vm.report_errors("dialog_instance", ["Missing text_id for string '" + text + "'"])
		text = "(no id) " + text

	# This BBCode may be the only way to center text for a RichTextLabel
	if ProjectSettings.get_setting("escoria/platform/dialog_force_centered"):
		text = "[center]" + text + "[/center]"

	play_intro = p_intro
	play_outro = p_outro
	total_time = text.length() / characters_per_second
	if !fixed_pos:
		var pos
		if character.has_node("dialog_pos"):
			pos = character.get_node("dialog_pos").get_global_position()
		else:
			pos = character.get_position()
		set_position(pos)

	if has_node("anchor/avatars"):
		var avatars = get_node("anchor/avatars")
		if avatars.get_child_count() > 0:
			var name
			if p_params.size() < 4:
				name = avatars.get_child(0).get_name()
			else:
				name = p_params[3]
			for i in range(0, avatars.get_child_count()):
				var c = avatars.get_child(i)
				if c.get_name() == name:
					c.show()
				else:
					c.hide()

	character.set_speaking(true)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "set_mode", "dialog")
	if has_node("animation") && play_intro:
		var anim = get_node("animation")
		if anim.has_animation("show"):
			if self is Node2D:
				show()
			anim.play("show")
			anim.seek(0, true)
		else:
			if self is Node2D:
				show()
			set_process(true)
	else:
		show()
		set_process(true)

	label.bbcode_enabled = true

	var parsed_ok = label.parse_bbcode(text)
	assert(parsed_ok == OK)
	label.bbcode_text = text
	label.set_visible_characters(0)  # This length is always adjusted later

	if self is Node2D:
		set_z_index(1)

	setup_speech(text_id)

func setup_speech(tid):

	if tid == null || tid == "":
		return

	if !vm.settings.speech_enabled:
		return

	var speech_path = ProjectSettings.get_setting("escoria/application/speech_path")
	var fname = speech_path + vm.settings.voice_lang + "/" + tid + speech_suffix
	printt(" ** loading speech ", fname)
	speech_stream = load(fname)
	if !speech_stream:
		printt("*** unable to load speech stream ", fname)
		return

	speech_stream.set_loop(false)

	var player = AudioStreamPlayer.new()
	player.set_name("speech_player")
	add_child(player)
	player.set_stream(speech_stream)
	player.volume_db = vm.settings.voice_volume * ProjectSettings.get_setting("escoria/application/max_voice_volume")
	player.play()

	if !player.is_playing():
		print(" *** not playing? :(")
		# error?
		speech_stream = null
		player.free()
		return

	#total_time = speech_stream.get_length() * 0.8 + 1.5
	#printt("total time ", total_time, speech_stream.get_length())
	speech_player = player

func game_paused(p_pause):
	if speech_stream == null || speech_player == null:
		return

	if p_pause:
		if speech_player.is_playing():
			speech_player.set_paused(true)
			speech_paused = true
	else:
		if speech_paused:
			speech_player.set_paused(false)


func _queue_free():
	queue_free()
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "set_mode", "default")
	vm.finished(context)


func anim_finished(anim_name):
	# TODO use the parameter here?
	var cur = get_node("animation").get_current_animation()
	if cur == "show":
		set_process(true)
	if cur == "hide":
		_queue_free()

func _ready():
	speech_suffix = ProjectSettings.get_setting("escoria/application/speech_suffix")
	add_to_group("events")
	if has_node("animation"):
		get_node("animation").connect("animation_finished", self, "anim_finished")
	label = get_node("anchor/text")

	# Ensure a supported speech locale has been set, or not set if no speech is desired
	var speech_locales_path = ProjectSettings.get_setting("escoria/application/speech_locales_path")
	if speech_locales_path:
		var speech_locales_def = load(speech_locales_path).new()
		assert(vm.settings.voice_lang in speech_locales_def.speech_locales)

	vm.connect("paused", self, "game_paused")
