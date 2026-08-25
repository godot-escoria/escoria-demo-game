class_name FloatingDialogTest
extends GdUnitTestSuite


const FLOATING_DIALOG_SCENE := preload(
	"res://addons/escoria-dialog-simple/types/floating.tscn"
)


var _say_finished_count := 0


func test_zero_text_duration_waits_for_longer_voice_clip() -> void:
	_say_finished_count = 0
	var previous_stop_talking_setting = ProjectSettings.get_setting(
		SimpleDialogSettings.STOP_TALKING_ANIMATION_ON
	)
	ProjectSettings.set_setting(
		SimpleDialogSettings.STOP_TALKING_ANIMATION_ON,
		SimpleDialogSettings.STOP_TALKING_ANIMATION_ON_END_OF_AUDIO
	)
	var speech_player := (
		escoria.object_manager.get_object(escoria.object_manager.SPEECH).node
		as ESCSpeechPlayer
	)
	var previous_stream := speech_player.stream.stream
	var voice_clip := AudioStreamWAV.new()
	voice_clip.format = AudioStreamWAV.FORMAT_8_BITS
	voice_clip.mix_rate = 8000
	voice_clip.data = PackedByteArray()
	voice_clip.data.resize(16000)

	var dialog_player := auto_free(Node.new())
	var floating_dialog := auto_free(FLOATING_DIALOG_SCENE.instantiate())
	add_child(dialog_player)
	dialog_player.add_child(floating_dialog)
	await get_tree().process_frame
	floating_dialog.set_process(false)
	floating_dialog.say_finished.connect(
		_remove_floating_dialog.bind(dialog_player, floating_dialog)
	)
	floating_dialog.text_node.text = ""
	floating_dialog._reading_speed_in_wpm = 200
	floating_dialog._word_regex.compile("\\S+")
	speech_player.stream.stream = voice_clip
	speech_player.stream.play()
	speech_player.stream.finished.connect(floating_dialog.voice_audio_finished)

	floating_dialog._on_dialog_line_typed(null, null)
	await get_tree().process_frame
	await get_tree().process_frame

	await get_tree().create_timer(0.05).timeout
	assert_int(_say_finished_count).is_zero()
	assert_bool(dialog_player.get_children().has(floating_dialog)).is_true()

	var timeout := get_tree().create_timer(3.0)
	while _say_finished_count == 0 and timeout.time_left > 0:
		await get_tree().process_frame

	assert_int(_say_finished_count).is_equal(1)
	assert_bool(dialog_player.get_children().has(floating_dialog)).is_false()

	speech_player.stream.stop()
	speech_player.stream.stream = previous_stream
	ProjectSettings.set_setting(
		SimpleDialogSettings.STOP_TALKING_ANIMATION_ON,
		previous_stop_talking_setting
	)


func _remove_floating_dialog(dialog_player: Node, floating_dialog: Node) -> void:
	_say_finished_count += 1
	dialog_player.remove_child(floating_dialog)
