extends Node

# This script is basically the scene-switcher.

# Global id of the last scene the player was before current scene
var last_scene_global_id
# Current scene room being displayed
var current_scene

var wait_level

var screen_ofs = Vector2(0, 0)

# ESCBackgroundMusic node
onready var bg_music = $bg_music
onready var scene_transition = $layers/curtain/scene_transition


# Set the new current scene
#
# #### Parameters
#
# - p_scene: Current scene to set
func set_scene(p_scene: Node):
	if !p_scene:
		escoria.logger.report_errors("main", ["Trying to set empty scene"])
	
	if current_scene != null:
		clear_scene()
		
	add_child(p_scene) 
	move_child(p_scene, 0)
	
	current_scene = p_scene
	check_game_scene_methods()

	set_camera_limits()


func clear_scene():
	if current_scene == null:
		return

	escoria.action_manager.clear_current_action()
	escoria.action_manager.clear_current_tool()

	remove_child(current_scene)
	current_scene.free()
	current_scene = null

func wait(params : Array, level):
	wait_level = level
	$layers/wait_timer.set_wait_time(float(params[0]))
	$layers/wait_timer.set_one_shot(true)
	$layers/wait_timer.start()


func set_camera_limits(camera_limit_id : int = 0):
	var limits = {}
	var scene_camera_limits = current_scene.camera_limits[camera_limit_id]
	if scene_camera_limits.size.x == 0 and scene_camera_limits.size.y == 0:
		var area = Rect2()
		for child in current_scene.get_children():
			if child is ESCBackground:
				area = child.get_full_area_rect2()
				break

		# if the background is smaller than the viewport, we want the camera to stick centered on the background
		if area.size.x == 0 or area.size.y == 0 or area.size < get_viewport().size:
			escoria.logger.report_warning("main.gd:set_camera_limits()", 
				"No limit area! Using viewport.")
			area.size = get_viewport().size

		escoria.logger.info("Setting camera limits from scene ", [area])
		limits = {
			"limit_left": area.position.x,
			"limit_right": area.position.x + area.size.x,
			"limit_top": area.position.y,
			"limit_bottom": area.position.y + area.size.y,
			"set_default": true,
		}
	else:
		limits = {
			"limit_left": scene_camera_limits.position.x,
			"limit_right": scene_camera_limits.position.x + scene_camera_limits.size.x,
			"limit_top": scene_camera_limits.position.y,
			"limit_bottom": scene_camera_limits.position.y + scene_camera_limits.size.y + screen_ofs.y * 2,
			"set_default": true,
		}
		escoria.logger.info("Setting camera limits from parameter ", [scene_camera_limits])

	current_scene.game.get_node("camera").set_limits(limits)
	current_scene.game.get_node("camera").set_offset(screen_ofs * 2)


"""
The game.tscn scene's root node script MUST implement the following methods.
If they do not exist, stop immediately. Implement them, even if empty
"""
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
	
