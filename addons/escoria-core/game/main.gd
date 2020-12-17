extends Node

# This script is basically the scene-switcher.

# Global id of the last scene the player was before current scene
var last_scene_global_id
# Current scene room being displayed
var current_scene

var wait_level

var screen_ofs = Vector2(0, 0)

func _ready():
	$layers/wait_timer.connect("timeout", self, "_on_wait_finished")

func set_scene(p_scene, run_events=true):
	"""
	Sets p_scene as current scene
	If run_events=true, plays the events defined in :setup event
	"""
	if !p_scene:
		escoria.report_errors("main", ["Trying to set empty scene"])

	# Ensure we don't have a regular event running when changing scenes
	if escoria.esc_runner.running_event:
		assert(escoria.esc_runner.running_event.ev_name == "load")

	if "esc_script" in p_scene and p_scene.esc_script and run_events:
		var events = escoria.esc_compiler.load_esc_file(p_scene.esc_script)

		# :setup is pretty much required in the code, but fortunately
		# we can help out with cases where one isn't necessary otherwise
		if not "setup" in events:
			var fake_setup = escoria.esc_compiler.compile_str(":setup\n")
			events["setup"] = fake_setup["setup"]

		escoria.esc_runner.run_event(events["setup"])
	
		# If scene was never visited, run "ready" event
		if !escoria.esc_runner.scenes_cache.has(p_scene.global_id) \
			and "ready" in events:
			escoria.esc_runner.run_event(events["ready"])

	if current_scene != null:
		clear_scene()
	
#	var game_scene = 
	
	get_node("/root").add_child(p_scene)
	set_current_scene(p_scene, run_events)
	set_camera_limits()


func set_current_scene(p_scene, run_events=true):
	current_scene = p_scene
	$"/root".move_child(current_scene, 0)

	# Loading a save game must set the scene but not run events
	if "events_path" in current_scene and current_scene.events_path and run_events:
		if escoria.esc_runner.game:
			# Having a game with `:setup` means we must wait for it to finish
			if "setup" in escoria.esc_runner.game:
				if not escoria.esc_runner.running_event:
					escoria.report_errors("main.gd:set_current_scene()", ["escoria.esc_runner.game has setup but no running_event"])

				if escoria.esc_runner.running_event.ev_name != "setup":
					escoria.report_errors("main.gd:set_current_scene()", ["escoria.esc_runner.game has setup but it is not running: " + escoria.esc_runner.running_event.ev_name])

				yield(escoria.esc_runner, "event_done")
		else:
			escoria.esc_compiler.load_file(current_scene.events_path)
			# For a new game, we must run `:setup` if available
			# and wait for it to finish
			if "setup" in escoria.esc_runner.game:
				escoria.esc_runner.run_event(escoria.esc_runner.game["setup"])
				yield(escoria.esc_runner, "event_done")

		# Because 1) changing a scene and 2) having a scene become ready
		# both call `set_current_scene`, we don't want to duplicate thing
		if not escoria.esc_runner.running_event:
			escoria.esc_runner.run_game()

	escoria.esc_runner.register_object("_scene", p_scene, true)  # Force overwrite of global


func clear_scene():
	if current_scene == null:
		return

	escoria.esc_runner.clear_current_action()
	escoria.esc_runner.clear_current_tool()
#	escoria.esc_runner.hover_clear_stack()
#	escoria.clear_inventory()

	last_scene_global_id = current_scene.global_id
	escoria.esc_runner.set_global("ESC_LAST_SCENE", last_scene_global_id, true)
	get_node("/root").remove_child(current_scene)
	current_scene.free()
	current_scene = null

func wait(params : Array, level):
	wait_level = level
	$layers/wait_timer.set_wait_time(float(params[0]))
	$layers/wait_timer.set_one_shot(true)
	$layers/wait_timer.start()

func _on_wait_finished():
	escoria.esc_level_runner.finished(wait_level)


func set_camera_limits():
	var limits = {}
	var scene_camera_limits = current_scene.camera_limits
	if scene_camera_limits.size.x == 0 and scene_camera_limits.size.y == 0:
		var area = Rect2()
		for child in current_scene.get_children():
			if child is ESCBackground:
				var pos = child.get_global_position()
				var size : Vector2
				if child.get_texture():
					size = child.get_texture().get_size()
				else:
					size = child.rect_size
					
				if child.rect_scale.x != 1 or child.rect_scale.y != 1:
					size.x *= child.rect_scale.x
					size.y *= child.rect_scale.y

				area = area.expand(pos)
				area = area.expand(pos + size)
				break

		# if the background is smaller than the viewport, we want the camera to stick centered on the background
		if area.size.x == 0 or area.size.y == 0 or area.size < get_viewport().size:
			printt("No limit area! Using viewport")
			area.size = get_viewport().size

		printt("setting camera limits from scene ", area)
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
		printt("setting camera limits from parameter ", scene_camera_limits)

	escoria.esc_runner.get_object("camera").set_limits(limits)
	escoria.esc_runner.get_object("camera").set_offset(screen_ofs * 2)
