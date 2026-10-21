class_name NewGameRoomLifecycleTest
extends GdUnitTestSuite

# Exercise the actual main scene, room/object/event managers, ASHES runtime,
# ESCRoom._ready and ESCLocation registration. Only game content is a fixture.
const FIXTURES := "res://addons/escoria-core/testing/new_game/"
const START := FIXTURES + "starting_room.tscn"
const OTHER := FIXTURES + "other_room.tscn"
const TIMEOUT_MS := 5000

var _start_script_before: ESCScript
var _setup_snapshots: Array[Dictionary] = []
var _ready_count := 0
var _new_game_count := 0


## Prepare isolated lifecycle counters and a minimal new-game script.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func before_test() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    escoria.set_game_paused(false)
    escoria.event_manager.interrupt([], false)
    escoria.event_manager.clear_event_queue()
    escoria.creating_new_game = false
    escoria.save_manager.is_loading_game = false
    _start_script_before = escoria.start_script
    escoria.start_script = escoria.esc_compiler.load_esc_file(FIXTURES + "restart.esc")
    escoria.event_manager.event_started.connect(_on_event_started)
    escoria.main.room_ready.connect(_on_room_ready)
    escoria.new_game_started.connect(_on_new_game_started)
    _setup_snapshots.clear()
    _ready_count = 0
    _new_game_count = 0
    await _change_room(START)
    _setup_snapshots.clear()
    _ready_count = 0


## Restore the start script and clear pending runtime events.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func after_test() -> void:
    escoria.set_game_paused(false)
    escoria.event_manager.interrupt([], false)
    escoria.event_manager.clear_event_queue()
    escoria.event_manager.event_started.disconnect(_on_event_started)
    escoria.main.room_ready.disconnect(_on_room_ready)
    escoria.new_game_started.disconnect(_on_new_game_started)
    escoria.start_script = _start_script_before
    escoria.save_manager.is_loading_game = false
    escoria.creating_new_game = false


## Verify a restart replaces the starting room and registers fresh objects before setup.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func test_restart_in_starting_room_replaces_room_before_setup() -> void:
    await _restart_and_check()


## Verify a restart from another room initializes the starting room once.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func test_restart_from_another_room_replaces_room_before_setup() -> void:
    await _change_room(OTHER)
    _setup_snapshots.clear()
    _ready_count = 0
    await _restart_and_check()


## Verify repeated restarts clear the lifecycle flag and stale registrations.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func test_repeated_restart_does_not_accumulate_state() -> void:
    for iteration in 3:
        _setup_snapshots.clear()
        _ready_count = 0
        await _restart_and_check()


## Verify restart resumes a paused game and interrupts the old active event.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func test_paused_menu_restart_interrupts_active_event() -> void:
    escoria.event_manager.queue_event(escoria.start_script.get_event_with_target("waiting"))
    await get_tree().process_frame
    assert_object(escoria.event_manager.get_running_event(escoria.event_manager.CHANNEL_FRONT)).is_not_null()
    escoria.game_scene.pause_game()
    assert_bool(get_tree().paused).is_true()
    await _restart_and_check()
    assert_bool(get_tree().paused).is_false()
    assert_bool(escoria.globals_manager.has("old_event_completed")).is_false()


## Verify an ordinary same-room transition leaves the current room intact.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func test_ordinary_same_room_transition_preserves_instance_and_registration() -> void:
    var room: ESCRoom = escoria.main.current_scene
    var location: Node = escoria.object_manager.get_object("restart_location").node
    escoria.room_manager.change_scene_to_file(START, false)
    await _frames(4)
    assert_object(escoria.main.current_scene).is_same(room)
    assert_object(escoria.object_manager.get_object("restart_location").node).is_same(location)
    assert_int(_setup_snapshots.size()).is_equal(0)
    assert_int(_ready_count).is_equal(0)


## Verify same-room loading reinitializes the existing room once without setup.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func test_same_room_save_load_reinitializes_existing_room_once_without_setup() -> void:
    var room: ESCRoom = escoria.main.current_scene
    var location: Node = escoria.object_manager.get_object("restart_location").node
    escoria.save_manager.is_loading_game = true
    escoria.room_manager.change_scene_to_file(START, false)
    await _wait_until(func(): return _ready_count > 0, "save-load room ready")
    await _wait_for_idle()
    await _frames(4)
    assert_object(escoria.main.current_scene).is_same(room)
    assert_object(escoria.object_manager.get_object("restart_location").node).is_same(location)
    assert_int(_setup_snapshots.size()).is_equal(0)
    assert_int(_ready_count).is_equal(1)
    assert_bool(room.enabled_automatic_transitions).is_false()
    assert_int(escoria.object_manager.current_room_key.room_instance_id).is_equal(room.get_instance_id())


func _restart_and_check() -> void:
    var old_room: ESCRoom = escoria.main.current_scene
    var old_instance_id := old_room.get_instance_id()
    var completed_before := _new_game_count
    escoria.new_game()
    await _wait_until(func(): return _new_game_count > completed_before, "new game completion")
    await _wait_until(func(): return _ready_count > 0, "restarted room ready")
    await _wait_for_idle()
    # Flush queued deletion: old tree_exited callbacks must not erase new items.
    await _frames(4)
    var room: ESCRoom = escoria.main.current_scene
    assert_int(room.get_instance_id()).is_not_equal(old_instance_id)
    assert_bool(is_instance_valid(old_room)).is_false()
    assert_str(room.scene_file_path).is_equal(START)
    assert_str(escoria.object_manager.current_room_key.room_global_id).is_equal("starting_room")
    assert_int(escoria.object_manager.current_room_key.room_instance_id).is_equal(room.get_instance_id())
    assert_int(_setup_snapshots.size()).is_equal(1)
    assert_int(_ready_count).is_equal(1)
    for snapshot in _setup_snapshots:
        assert_int(snapshot.room_id).is_equal(room.get_instance_id())
        assert_int(snapshot.key_id).is_equal(room.get_instance_id())
        assert_bool(snapshot.registered).is_true()
    assert_bool(escoria.object_manager.has("restart_location")).is_true()
    if escoria.object_manager.has("restart_location"):
        assert_object(escoria.object_manager.get_object("restart_location").node).is_same(room.get_node("Start"))
    assert_bool(escoria.globals_manager.get_global("setup_executed")).is_true()
    assert_bool(escoria.creating_new_game).is_false()


func _change_room(path: String) -> void:
    if is_instance_valid(escoria.main.current_scene) and escoria.main.current_scene.scene_file_path == path:
        return
    var ready_before := _ready_count
    escoria.room_manager.change_scene_to_file(path, false)
    await _wait_until(func(): return _ready_count > ready_before, "initial room ready")
    await _wait_for_idle()
    await _frames(4)


func _on_event_started(event_name: String) -> void:
    if event_name != escoria.event_manager.EVENT_SETUP:
        return
    var room: ESCRoom = escoria.main.current_scene
    _setup_snapshots.append({
        "room_id": room.get_instance_id(),
        "key_id": escoria.object_manager.current_room_key.room_instance_id,
        "registered": escoria.object_manager.has("restart_location") and escoria.object_manager.get_object("restart_location").node == room.get_node("Start")
    })


func _on_room_ready() -> void:
    _ready_count += 1


func _on_new_game_started() -> void:
    _new_game_count += 1


func _wait_until(predicate: Callable, description: String) -> void:
    var deadline := Time.get_ticks_msec() + TIMEOUT_MS
    while not predicate.call() and Time.get_ticks_msec() < deadline:
        await get_tree().process_frame
    assert_bool(predicate.call()).override_failure_message("Timed out waiting for " + description).is_true()


func _frames(count: int) -> void:
    for frame in count:
        await get_tree().process_frame


func _wait_for_idle() -> void:
    await _wait_until(
        func(): return escoria.event_manager.get_running_event(escoria.event_manager.CHANNEL_FRONT) == null and escoria.event_manager.events_queue[escoria.event_manager.CHANNEL_FRONT].is_empty(),
        "room transition events to finish"
    )
