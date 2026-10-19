class_name ESCObjectSaveLifecycleTest
extends GdUnitTestSuite


## Save retained object state after a room scene exits and frees its nodes.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func test_save_preserves_retired_room_state_after_scene_is_freed() -> void:
    var manager := ESCObjectManager.new()
    var old_room := ESCRoom.new()
    old_room.global_id = "retired_room"
    var next_room := ESCRoom.new()
    next_room.global_id = "current_room"
    var old_scene := Node2D.new()
    var item := Node2D.new()
    old_scene.add_child(item)
    add_child(old_scene)
    manager.set_current_room(old_room)
    var object := ESCObject.new("opened_door", item)
    manager.register_object(object, old_room)
    object.set_state("opened")
    object.active = false
    # Exercise the real exit callback and retained-state policy, without
    # starting unrelated room UI, player, or transition animations.
    manager.set_current_room(next_room)
    old_scene.queue_free()
    await get_tree().process_frame
    await get_tree().process_frame
    assert_bool(is_instance_valid(object.node)).is_false()
    assert_bool(manager.has("opened_door", old_room)).is_true()
    assert_int(manager.current_room_key.room_instance_id).is_equal(next_room.get_instance_id())
    var save := ESCSaveGame.new()
    manager.save_game(save)
    var saved_room: Dictionary = save.objects.get("retired_room", {})
    var saved_object: Dictionary = saved_room.get("opened_door", {})
    assert_str(saved_object.get("state", "")).is_equal("opened")
    assert_bool(saved_object.get("active", true)).is_false()
    assert_bool(saved_object.has("interactive")).is_true()
    assert_bool(saved_object.has("global_transform")).is_false()
    old_room.free()
    next_room.free()


## Save live players and ordinary objects through the same manager path.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func test_save_keeps_live_player_and_live_object_data() -> void:
    var manager := ESCObjectManager.new()
    var room := ESCRoom.new()
    room.global_id = "live_room"
    manager.set_current_room(room)
    var player := ESCPlayer.new()
    player.is_movable = false
    var item := Node2D.new()
    var player_object := ESCObject.new("player", player)
    var item_object := ESCObject.new("door", item)
    manager.register_object(player_object, room, false, false)
    manager.register_object(item_object, room, false, false)
    item_object.set_state("locked")
    var save := ESCSaveGame.new()
    manager.save_game(save)
    assert_bool(save.objects["live_room"].has("player")).is_true()
    assert_str(save.objects["live_room"]["player"]["state"]).is_equal(ESCObject.STATE_DEFAULT)
    assert_str(save.objects["live_room"]["door"]["state"]).is_equal("locked")
    player.free()
    item.free()
    room.free()
