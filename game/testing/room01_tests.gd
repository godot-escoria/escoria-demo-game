# GdUnit generated TestSuite
class_name Room01Test
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = '${source_resource_path}'

@onready
var _change_scene_cmd: ChangeSceneCommand = ChangeSceneCommand.new()

func test_simulate_frames(timeout = 15000) -> void:
	_change_scene_cmd.run(["res://game/rooms/room01/room01.tscn", false])
	
	# Create the scene runner for scene room01
	#var runner := scene_runner("res://game/rooms/room01/room01.tscn")
	var runner := scene_runner(escoria.main.current_scene)

	# Get access to the loaded scene node
	var room_scene:ESCRoom = runner.scene()
	var player_object = room_scene.player
	var target_pos1 = room_scene.get_node("orients_down_on_arrival")
	var target_pos2 = room_scene.get_node("set_angle_by_esc")
	#var target_pos3 = room_scene.get_node("turn_to_r_door_by_esc")
	
	await runner.simulate_frames(300)
	# After 300 frames, the player should be on point 1
	assert_object(player_object.position.round()).is_equal(
		target_pos1.position.round())
	
	await runner.simulate_frames(300)
	# After 600 frames, the player should be on point 2
	assert_object(player_object.position.round()).is_equal(
		target_pos2.position.round())

	await runner.simulate_frames(700)
	# After 1200 frames, the player should be on point 1 again
	assert_object(player_object.position.round()).is_equal(
		target_pos1.position.round())
