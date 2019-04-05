extends Node2D

var animation

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

var dialog_pos  # The designated position
var pos         # The transformed position
var prev_pos    # Check this to see if `character` moved and reposition

var dialog_min_vis = ProjectSettings.get_setting("escoria/application/dialog_minimum_visible_seconds")

var damp_db = ProjectSettings.get_setting("escoria/application/dialog_damp_music_by_db")
onready var bg_music = $"/root/main/layers/telon/bg_music/stream"

export var fixed_pos = false

func _process(time):
	if finished:
		return

	if not fixed_pos:
		dialog_pos = character.get_dialog_pos()
		pos = vm.camera.zoom_transform.xform(dialog_pos)

		if prev_pos != pos:
			set_position(pos)
			prev_pos = pos

	if force_disable_typewriter_text or !typewriter_text:
		label.set_visible_characters(label.get_total_character_count())
		text_done = true

	elapsed += time

	# For eg. a short fallback dialog, leave the text for it visible. The player
	# will be able to skip it anyway.
	if dialog_min_vis and elapsed < dialog_min_vis:
		return

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
		return

	if elapsed > text_timeout_seconds and (!speech_player or !speech_player.is_playing()):
		finish()
		return

	if vm.settings.skip_dialog && speech_stream != null && !speech_player.is_playing() && text_done:
		finish()
		return

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

	if bg_music.is_playing():
		bg_music.volume_db += damp_db

	if animation and play_outro:
		if animation.has_animation("hide"):
			animation.play("hide")
	elif not animation:
		_queue_free()

func _clamp(dialog_pos):
	var width = float(ProjectSettings.get("display/window/size/width"))
	var height = float(ProjectSettings.get("display/window/size/height"))
	var my_size = $"anchor/text".get_size()
	var center_offset = my_size.x / 2

	var dist_from_right = width - (dialog_pos.x + center_offset)
	var dist_from_left = dialog_pos.x - center_offset
	var dist_from_bottom = height - (dialog_pos.y + my_size.y)
	var dist_from_top = dialog_pos.y - my_size.y

	if dist_from_right < 0:
		dialog_pos.x += dist_from_right
	if dist_from_left < 0:
		dialog_pos.x -= dist_from_left
	if dist_from_bottom < 0:
		dialog_pos.y += dist_from_bottom
	if dist_from_top < 0:
		dialog_pos.y -= dist_from_top

	return dialog_pos

func init(p_params, p_context, p_intro, p_outro):
	character = vm.get_object(p_params[0])
	context = p_context
	text = p_params[1]
	var force_ids = ProjectSettings.get_setting("escoria/platform/force_text_ids")
	var tag_untranslated = ProjectSettings.get_setting("escoria/platform/tag_untranslated_strings")
	var sep = text.find(":\"")
	var text_id = null
	if sep > 0:
		text_id = text.substr(0, sep)
		text = text.substr(sep + 2, text.length() - (sep + 2))

		if TranslationServer.get_locale() != ProjectSettings.get_setting("escoria/platform/development_lang"):
			var ptext = TranslationServer.translate(text_id)
			# An untranslated string comes back as it was, so we must tag it as not translated
			if ptext != text_id and ptext != text:
				text = ptext
			elif tag_untranslated:
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
		dialog_pos = character.get_dialog_pos()

		pos = vm.camera.zoom_transform.xform(dialog_pos)
		set_position(pos)
		prev_pos = pos

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
	if animation and play_intro:
		if animation.has_animation("show"):
			animation.play("show")
			animation.seek(0, true)
		else:
			show()
			set_process(true)
	else:
		show()
		set_process(true)

	if character.dialog_color:
		label["custom_colors/default_color"] = character.dialog_color

	label.bbcode_enabled = true

	var parsed_ok = label.parse_bbcode(text)

	if parsed_ok != OK:
		vm.report_errors("dialog_instance", ["Label failed parsing bbcode: " + text])

	label.bbcode_text = "\n" + text
	label.set_visible_characters(0)  # This length is always adjusted later

	set_z_index(1)

	setup_speech(text_id)

func setup_speech(tid):
	if tid == null || tid == "":
		return

	if !vm.settings.speech_enabled:
		return

	var use_binaural = ProjectSettings.get_setting("escoria/application/binaural_speech")

	var speech_path = ProjectSettings.get_setting("escoria/application/speech_path")
	var fname = speech_path + vm.settings.voice_lang + "/" + tid + speech_suffix
	printt(" ** loading speech ", fname)
	speech_stream = load(fname)
	if !speech_stream:
		printt("*** unable to load speech stream ", fname)
		return

	speech_stream.set_loop(false)

	if use_binaural:
		speech_player = AudioStreamPlayer2D.new()
	else:
		speech_player = AudioStreamPlayer.new()

	speech_player.set_name("speech_player_" + character.global_id if "global_id" in character else "player")
	speech_player.bus = "Speech"

	if use_binaural:
		character.add_child(speech_player)
	else:
		add_child(speech_player)

	speech_player.set_stream(speech_stream)
	speech_player.volume_db = vm.settings.voice_volume * ProjectSettings.get_setting("escoria/application/max_voice_volume")

	if bg_music.is_playing():
		bg_music.volume_db -= damp_db

	speech_player.play()

	# XXX: For whatever reason the AudioStreamPlayer2D does not appear to be playing, but it actually is
	if not use_binaural and not speech_player.is_playing():
		print(" *** not playing? :(")
		# error?
		speech_stream = null
		speech_player.free()
		return

	#total_time = speech_stream.get_length() * 0.8 + 1.5
	#printt("total time ", total_time, speech_stream.get_length())

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
	if speech_player != null:
		speech_player.free()

	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "set_mode", "default")
	vm.finished(context)
	queue_free()


#warning-ignore:unused_argument
func anim_finished(anim_name):
	# TODO use the parameter here?
	var cur = animation.get_current_animation()
	if cur == "show":
		set_process(true)
	if cur == "hide":
		_queue_free()

func set_position(pos):
	.set_position(_clamp(pos))

func _ready():
	var conn_err

	speech_suffix = ProjectSettings.get_setting("escoria/application/speech_suffix")
	add_to_group("events")
	if has_node("animation"):
		animation = $"animation"

		conn_err = animation.connect("animation_finished", self, "anim_finished")
		if conn_err:
			vm.report_errors("dialog_instance", ["animation_finished -> anim_finished error: " + String(conn_err)])

	label = get_node("anchor/text")

	# Ensure a supported speech locale has been set, or not set if no speech is desired
	var speech_locales_path = ProjectSettings.get_setting("escoria/application/speech_locales_path")
	if speech_locales_path:
		var speech_locales_def = load(speech_locales_path).new()

		if not vm.settings.voice_lang in speech_locales_def.speech_locales:
			vm.report_errors("dialog_instance", ["Settings voice_lang not in defined speech locales: " + vm.settings.voice_lang])

	conn_err = vm.connect("paused", self, "game_paused")
	if conn_err:
		vm.report_errors("dialog_instance", ["paused -> game_paused error: " + String(conn_err)])


