# Escoria main room handling and scene switcher
extends Node

# This script is basically the scene-switcher.


# Signal sent when the room is loaded and ready.
signal room_ready


# Global id of the last scene the player was before current scene
var last_scene_global_id: String

# Current scene room being displayed
var current_scene: Node

# The Escoria context currently in wait state
var wait_level

# Reference to the scene transition node
onready var scene_transition: ESCTransitionPlayer


# Connect the wait timer event
func _ready() -> void:
	scene_transition = ESCTransitionPlayer.new()
	$layers/curtain.add_child(scene_transition)
	$layers/wait_timer.connect("timeout", self, "_on_wait_finished")


# Set current scene
#
# #### Parameters
#
# - p_scene: Scene to set
func set_scene(p_scene: Node) -> void:
	if !p_scene:
		escoria.logger.report_errors("main", ["Trying to set empty scene"])

	if current_scene != null:
		clear_scene()

	if not p_scene.is_inside_tree():
		# Set the scene to visible for :setup events. Note that the room's 
		# _ready() method will ensure that visibility is set to true when
		# :setup is complete.
		p_scene.z_index = -100
		add_child(p_scene) 
		move_child(p_scene, 0)

	current_scene = p_scene
	
	check_game_scene_methods()

	set_camera_limits()
	
	emit_signal("room_ready")


# Cleanup the current scene
func clear_scene() -> void:
	if current_scene == null:
		return

	escoria.action_manager.clear_current_action()
	escoria.action_manager.clear_current_tool()
	
	if escoria.game_scene.get_parent() == current_scene:
		current_scene.remove_child(escoria.game_scene)

	current_scene.cleanup()
			
	current_scene.get_parent().remove_child(current_scene)
	
	current_scene.queue_free()
	current_scene = null


# Triggered, when the wait has finished
func _on_wait_finished() -> void:
	escoria.esc_level_runner.finished(wait_level)


# Set the camera limits
#
# #### Parameters
#
# * camera_limits_id: The id of the room's camera limits to set
func set_camera_limits(camera_limit_id: int = 0) -> void:
	var limits = {}
	var scene_camera_limits = current_scene.camera_limits[camera_limit_id]
	if scene_camera_limits.size.x == 0 and scene_camera_limits.size.y == 0:
		var area = Rect2()
		for child in current_scene.get_children():
			if child is ESCBackground:
				area = child.get_full_area_rect2()
				break

		# if the background is smaller than the viewport, we want the camera 
		# to stick centered on the background
		if area.size.x == 0 or area.size.y == 0 \
				or area.size < get_viewport().size:
			escoria.logger.report_warnings(
				"main.gd:set_camera_limits()",
				[
					"No limit area! Using viewport."
				]
			)
			area.size = get_viewport().size

		escoria.logger.info("Setting camera limits from scene ", [area])
		limits = ESCCameraLimits.new(
			area.position.x,
			area.position.x + area.size.x,
			area.position.y,
			area.position.y + area.size.y
		)
	else:
		limits = ESCCameraLimits.new(
			scene_camera_limits.position.x,
			scene_camera_limits.position.x + \
					scene_camera_limits.size.x,
			scene_camera_limits.position.y,
			scene_camera_limits.position.y + \
					scene_camera_limits.size.y
		)
		escoria.logger.info(
			"Setting camera limits from parameter ", 
			[scene_camera_limits]
		)

	escoria.object_manager.get_object(
		escoria.object_manager.CAMERA
	).node.set_limits(limits)


func save_game(p_savegame_res: Resource) -> void:
	p_savegame_res.main = {
		ESCSaveGame.MAIN_LAST_SCENE_GLOBAL_ID_KEY: last_scene_global_id,
		ESCSaveGame.MAIN_CURRENT_SCENE_FILENAME_KEY: current_scene.filename \
				if current_scene != null \
				else "No current scene (not loaded yet)"
	}


# Sanity check that the game.tscn scene's root node script MUST
# implement the following methods. If they do not exist, stop immediately.
# Implement them, even if empty
func check_game_scene_methods():
	assert(current_scene.game.has_method("left_click_on_bg"))
	assert(current_scene.game.has_method("right_click_on_bg"))
	assert(current_scene.game.has_method("left_double_click_on_bg"))
	
	assert(current_scene.game.has_method("element_focused"))
	assert(current_scene.game.has_method("element_unfocused"))
	
	assert(current_scene.game.has_method("left_click_on_item"))
	assert(current_scene.game.has_method("right_click_on_item"))
	assert(current_scene.game.has_method("left_double_click_on_item"))
	
	assert(current_scene.game.has_method("open_inventory"))
	assert(current_scene.game.has_method("close_inventory"))
	
	assert(current_scene.game.has_method("left_click_on_inventory_item"))
	assert(current_scene.game.has_method("right_click_on_inventory_item"))
	assert(current_scene.game.has_method("left_double_click_on_inventory_item"))
	
	assert(current_scene.game.has_method("inventory_item_focused"))
	assert(current_scene.game.has_method("inventory_item_unfocused"))
	
	assert(current_scene.game.has_method("mousewheel_action"))
	
	assert(current_scene.game.has_method("hide_ui"))
	assert(current_scene.game.has_method("show_ui"))
	assert(current_scene.game.has_method("_on_event_done"))
	
