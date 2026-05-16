# GdUnit generated TestSuite
class_name ESCObjectManagerTest
extends GdUnitTestSuite


func test_reset_game_state_clears_persisted_room_object_state() -> void:
	var object_manager := ESCObjectManager.new()
	var room := ESCRoom.new()
	room.global_id = "test_room"
	object_manager.set_current_room(room)

	var first_item := ESCItem.new()
	first_item.global_id = "test_item"
	var first_object := ESCObject.new(first_item.global_id, first_item)
	object_manager.register_object(first_object, room, false, false)
	first_object.set_state("opened")

	var room_key := ESCRoomObjectsKey.new()
	room_key.room_global_id = room.global_id
	room_key.room_instance_id = room.get_instance_id()
	object_manager.unregister_object(first_object, room_key)
	assert_bool(object_manager.has(first_item.global_id, room)).is_true()

	object_manager.reset_game_state()
	assert_bool(object_manager.has(first_item.global_id, room)).is_false()

	var second_item := ESCItem.new()
	second_item.global_id = "test_item"
	var second_object := ESCObject.new(second_item.global_id, second_item)
	object_manager.set_current_room(room)
	object_manager.register_object(second_object, room, false, false)

	assert_str(object_manager.get_object(second_item.global_id, room).state).is_equal(
		ESCObject.STATE_DEFAULT
	)

	first_item.free()
	second_item.free()
	room.free()


func test_reset_game_state_preserves_reserved_objects() -> void:
	var object_manager := ESCObjectManager.new()
	var music_node := Node.new()

	object_manager.register_object(
		ESCObject.new(ESCObjectManager.MUSIC, music_node),
		null,
		true,
		false
	)

	object_manager.reset_game_state()

	assert_bool(object_manager.has(ESCObjectManager.MUSIC)).is_true()
	assert_object(object_manager.get_object(ESCObjectManager.MUSIC).node).is_same(music_node)

	music_node.free()


func test_reset_game_state_clears_saved_terrain_state() -> void:
	var object_manager := ESCObjectManager.new()
	var room := ESCRoom.new()
	room.global_id = "test_room"
	var navigation_region := NavigationRegion2D.new()

	object_manager.set_current_room(room)
	object_manager.register_terrain(
		ESCObject.new("test_terrain", navigation_region),
		room
	)
	assert_int(object_manager.room_terrains.size()).is_equal(1)

	object_manager.reset_game_state()

	assert_int(object_manager.room_terrains.size()).is_equal(0)

	navigation_region.free()
	room.free()
