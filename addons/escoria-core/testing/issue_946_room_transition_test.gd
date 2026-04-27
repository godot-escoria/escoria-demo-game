class_name Issue946RoomTransitionTest
extends GdUnitTestSuite


const MARK_SCRIPT := "res://game/characters/mark/mark.esc"
const ROOM_05 := "res://game/rooms/room05/room05.tscn"
const ROOM_06 := "res://game/rooms/room06/room06.tscn"


var _compiler_before: ESCCompiler


class CountingCompiler extends ESCCompiler:
	var load_counts: Dictionary = {}


	func load_esc_file(path: String, associated_global_id: String = "") -> ESCScript:
		load_counts[path] = load_counts.get(path, 0) + 1
		return super.load_esc_file(path, associated_global_id)


	func get_load_count(path: String) -> int:
		return load_counts.get(path, 0)


	func reset_counts() -> void:
		load_counts.clear()


func before() -> void:
	_compiler_before = escoria.esc_compiler
	escoria.esc_compiler = CountingCompiler.new()
	escoria.event_manager.interrupt([], false)
	escoria.event_manager.clear_event_queue()


func after() -> void:
	escoria.event_manager.interrupt([], false)
	escoria.event_manager.clear_event_queue()
	escoria.esc_compiler = _compiler_before


func test_room_6_to_room_5_loads_player_script_once() -> void:
	var compiler := escoria.esc_compiler as CountingCompiler

	await _change_scene_and_wait(ROOM_06, false)

	compiler.reset_counts()

	await _change_scene_and_wait(ROOM_05, true)
	await _wait_for_frames(3)

	assert_object(escoria.object_manager.get_object("player")).is_not_null()
	assert_int(compiler.get_load_count(MARK_SCRIPT)).is_equal(1)


func _change_scene_and_wait(room_path: String, enable_automatic_transition: bool) -> void:
	var room_ready: Signal = escoria.main.room_ready
	ChangeSceneCommand.new().run([room_path, enable_automatic_transition])
	await room_ready
	if enable_automatic_transition:
		await _wait_for_event_finished(escoria.event_manager.EVENT_TRANSITION_IN)


func _wait_for_event_finished(event_name: String) -> void:
	for attempt in 60:
		var rc = await escoria.event_manager.event_finished
		if rc[1] == event_name:
			return

	assert_str("").is_equal(event_name)


func _wait_for_frames(count: int) -> void:
	for frame in count:
		await get_tree().process_frame
