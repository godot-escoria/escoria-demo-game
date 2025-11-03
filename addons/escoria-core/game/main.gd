## Escoria main scene script.
##
## This script is basically the scene-switcher.
extends Node


## Signal sent when the room is loaded and ready.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
signal room_ready


## Global id of the last scene the player was before current scene
var last_scene_global_id: String

## Current scene room being displayed
var current_scene: Node

## Scene that was previously the current scene.
var previous_scene: Node

## The Escoria context currently in wait state
var wait_level

## Reference to the scene transition node
@onready var scene_transition: ESCTransitionPlayer

## Connect the wait timer event.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _ready() -> void:
	scene_transition = ESCTransitionPlayer.new()
	$layers/curtain.add_child(scene_transition)
	$layers/wait_timer.connect("timeout", Callable(self, "_on_wait_finished"))


## Called when the node is removed from the scene tree.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _exit_tree():
	$layers/curtain.remove_child(scene_transition)
	scene_transition.queue_free()

## Sets the current scene[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_scene|`Node`|Scene to set|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_scene(p_scene: Node) -> void:
	if !p_scene:
		escoria.logger.error(
			self,
			"Can't change to an empty scene. Please specify the scene name."
		)

	previous_scene = current_scene

	if is_instance_valid(previous_scene):
		_disable_collisions()

	if not p_scene.is_inside_tree():
		# Set the scene's visiblity for :setup events if the new room is not the
		# same one as the current room.
		if not _is_same_scene(current_scene, p_scene):
			p_scene.visible = false

		escoria.object_manager.set_current_room(p_scene)
		add_child(p_scene)

		# In cases where the room being created doesn't return because of a
		# coroutine, finish_current_scene_init() will already have been called
		# and so we don't want to risk repeating ourselves.
		if p_scene == current_scene:
			return

		# This actually moves the scene closest to the root node, but will
		# still be drawn behind the next node, which should be the previous
		# room.
		move_child(p_scene, 0)

	current_scene = p_scene
	last_scene_global_id = p_scene.global_id


## Only called by the room manager in the case where it hasn't executed a coroutine prior to calling set_scene_finish(). ### Parameters[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_scene|`Node`|The scene currently being initialized by set_scene.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func finish_current_scene_init(p_scene: Node) -> void:
	if is_ancestor_of(p_scene):
		move_child(p_scene, 0)

	current_scene = p_scene


## Completes the room swap and should be called by the room manager at the appropriate time.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_scene_finish() -> void:
	# Final check for the critical game scene's existence.
	check_game_scene_methods()

	# Make our new scene visible.
	current_scene.visible = true

	clear_previous_scene()
	room_ready.emit()


## Cleanup the previous scene if there was one.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func clear_previous_scene() -> void:
	if previous_scene == null:
		return

	escoria.action_manager.clear_current_action()
	escoria.action_manager.clear_current_tool()

	if escoria.game_scene.get_parent() == previous_scene:
		previous_scene.remove_child(escoria.game_scene)

	previous_scene.visible = false
	previous_scene.get_parent().remove_child(previous_scene)

	previous_scene.queue_free()
	previous_scene = null


## Triggered, when the wait has finished.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _on_wait_finished() -> void:
	escoria.esc_level_runner.finished(wait_level)


## Set the camera limits[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |camera_limit_id|`int`|Index of the camera limit configuration to apply.|no|[br]
## |scene|`Node`|The scene to set the camera limits for. We make this optional since most times it'll be current_scene that needs setting; however, e.g. when starting up Escoria, we might not have already set the current_scene. camera_limits_id The id of the room's camera limits to set|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_camera_limits(camera_limit_id: int = 0, scene: Node = current_scene) -> void:
	var limits = {}
	var last_available_camera_limit = scene.camera_limits.size() - 1
	if camera_limit_id > last_available_camera_limit:
		escoria.logger.error(
			self,
			"Camera3D limit %d requested. Last available camera limit is %d." % [
				camera_limit_id,
				last_available_camera_limit
			]
		)
	var scene_camera_limits = scene.camera_limits[camera_limit_id]
	if scene_camera_limits.size.x == 0 and scene_camera_limits.size.y == 0:
		var area = Rect2()
		for child in scene.get_children():
			if child is ESCBackground:
				area = child.get_full_area_rect2()
				break

		# if the background is smaller than the viewport, we want the camera
		# to stick centered on the background
		if area.size.x == 0 or area.size.y == 0 \
				or area.size < get_viewport().size:
			escoria.logger.warn(
				self,
				"Defined camera is smaller than the viewport. Using viewport size."
			)
			area.size = get_viewport().size

		escoria.logger.info(
			self,
			"Setting camera limits from scene " + str(area)
		)
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
			self,
			"Setting camera limits using configured parameters " + str(scene_camera_limits)
		)

	escoria.object_manager.get_object(
		escoria.object_manager.CAMERA
	).node.set_limits(limits)


## Save the game state to the provided savegame resource.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_savegame_res|`Resource`|The savegame resource to write to.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func save_game(p_savegame_res: Resource) -> void:
	p_savegame_res.main = {
		ESCSaveGame.MAIN_LAST_SCENE_GLOBAL_ID_KEY: last_scene_global_id,
		ESCSaveGame.MAIN_CURRENT_SCENE_FILENAME_KEY: current_scene.scene_file_path \
				if current_scene != null \
				else "No current scene (not loaded yet)"
	}


## Sanity check that the game.tscn scene's root node script MUST implement the following methods. If they do not exist, stop immediately. Implement them, even if empty[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
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
	assert(current_scene.game.has_method("escoria_hide_ui"))
	assert(current_scene.game.has_method("escoria_show_ui"))
	assert(current_scene.game.has_method("_on_event_done"))


## Determines whether two scenes represent the same room.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |scene_1|`Node`|Scene to be compared.|yes|[br]
## |scene_2|`Node`|Other scene to be compared.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns true iff the two scenes represent the same room. (`bool`)
func _is_same_scene(scene_1: Node, scene_2: Node) -> bool:
	if scene_1 is ESCRoom and scene_2 is ESCRoom:
		return scene_1.global_id == scene_2.global_id

	return false


## Disable collisions in the previous scene so if we have two scenes in the same game tree, collisions won't result.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _disable_collisions() -> void:
	var items_to_disable = previous_scene.get_tree().get_nodes_in_group(escoria.GROUP_ITEM_CAN_COLLIDE)

	for item in items_to_disable:
		if is_instance_valid(item.collision):
			item.collision.disabled = true
		if item is Area2D:
			item.monitoring = false
			item.monitorable = false

# ###################################################################
# Facades for current_scene

## Hide the UI of the current scene.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func hide_ui() -> void:
	if escoria.main.current_scene != null:
		escoria.main.current_scene.game.hide_ui()

## Hide the current scene.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func hide_current_scene() -> void:
	if escoria.main.current_scene != null:
		escoria.main.current_scene.hide()

## Show the UI of the current scene.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func show_ui() -> void:
	if escoria.main.current_scene != null:
		escoria.main.current_scene.game.show_ui()

## Show the current scene.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func show_current_scene() -> void:
	if escoria.main.current_scene != null:
		escoria.main.current_scene.show()
