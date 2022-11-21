# A base class for ESC game scenes
# An extending class can be used in the project settings and is responsible
# for managing very basic game features and controls
extends Node2D
class_name ESCGame


# Emitted when the user has confirmed the crash popup
signal crash_popup_confirmed

# Signal sent when pause menu has to be displayed
signal request_pause_menu


# Editor debug modes
# NONE - No debugging
# MOUSE_TOOLTIP_LIMITS - Visualize the tooltip limits
enum EDITOR_GAME_DEBUG_DISPLAY {
	NONE,
	MOUSE_TOOLTIP_LIMITS
}


# The main menu node
export(NodePath) var main_menu

# The main menu node
export(NodePath) var pause_menu

# The safe margin around tooltips
export(float) var mouse_tooltip_margin = 50.0

# Which (if any) debug mode for the editor is used
export(EDITOR_GAME_DEBUG_DISPLAY) var editor_debug_mode = \
		EDITOR_GAME_DEBUG_DISPLAY.NONE setget _set_editor_debug_mode

# The Control node underneath which all UI must be placed.
# This should be a Control node and NOT a CanvasLayer (or any other type of) node.
export(NodePath) var ui_parent_control_node

# A reference to the node handling tooltips
var tooltip_node: Object

# Boolean indicating whether the game scene is ready to accept inputs
# from the player. This enables using escoria.is_ready_for_inputs() in _input()
# function of game.gd script.
var room_ready_for_inputs: bool = false


# Function called when ESCGame enters the scene tree.
func _enter_tree():
	escoria.event_manager.connect(
		"event_finished",
		self,
		"_on_event_done"
	)
	escoria.action_manager.connect(
		"action_finished",
		self,
		"_on_action_finished"
	)

	escoria.main.connect(
		"room_ready",
		self,
		"_on_room_ready"
	)


# Function called when ESCGame exits the scene tree.
func _exit_tree():
	escoria.event_manager.disconnect(
		"event_finished",
		self,
		"_on_event_done"
	)
	escoria.action_manager.disconnect(
		"action_finished",
		self,
		"_on_action_finished"
	)

	escoria.main.disconnect(
		"room_ready",
		self,
		"_on_room_ready"
	)


# Ready function
func _ready():
	escoria.settings_manager.apply_settings()
	connect("crash_popup_confirmed", escoria, "quit",
		[], CONNECT_ONESHOT)


# Handle debugging visualizations
func _draw():
	if not Engine.is_editor_hint():
		return
	if editor_debug_mode == EDITOR_GAME_DEBUG_DISPLAY.NONE:
		return

	if editor_debug_mode == EDITOR_GAME_DEBUG_DISPLAY.MOUSE_TOOLTIP_LIMITS:
		var mouse_limits: Rect2 = get_viewport_rect().grow(
			-mouse_tooltip_margin
		)
		print("ESC {0}".format([mouse_limits]))

		# Draw lines for tooltip limits
		draw_rect(mouse_limits, ColorN("red"), false, 10.0)


# Clears the tooltip content (if an ESCTooltip node exists in UI)
func clear_tooltip():
	if tooltip_node != null:
		(tooltip_node as ESCTooltip).clear()


# Sets up and performs default walking action
#
# #### Parameters
#
# - destination: Destination to walk to
# - params: Parameters for the action
# - can_interrupt: if true, this command will interrupt any ongoing event
func do_walk(destination, params: Array = [], can_interrupt: bool = false) -> void:
	if can_interrupt:
		escoria.event_manager.interrupt()

	escoria.action_manager.clear_current_action()

	var walk_fast = false

	if params.size() > 1:
		walk_fast = true if params[1] else false

	# Check moving object.
	if not escoria.object_manager.has(params[0]):
		escoria.logger.error(
			self,
			"Walk action requested on nonexisting object: %s." % params[0]
		)
		return

	var moving_obj = escoria.object_manager.get_object(params[0])
	var target

	if destination is String:
		if not escoria.object_manager.has(destination):
			escoria.logger.error(
				self,
				"Walk action requested to nonexisting object: %s." % destination
			)
			return

		target = escoria.object_manager.get_object(destination)
	elif destination is Vector2:
		target = destination

	escoria.action_manager.perform_walk(moving_obj, target, walk_fast)


# Called when the player left clicks on the background
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - position: Position clicked
func left_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		do_walk(
			position,
			[escoria.main.current_scene.player.global_id],
			true
		)
	else:
		escoria.logger.trace(
			self,
			"No player loaded for current scene. Ignoring left click on background."
		)


# Called when the player right clicks on the background
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - position: Position clicked
func right_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		do_walk(
			position,
			[escoria.main.current_scene.player.global_id],
			true
		)
	else:
		escoria.logger.trace(
			self,
			"No player loaded for current scene. Ignoring right click on background."
		)


# Called when the player double clicks on the background
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - position: Position clicked
func left_double_click_on_bg(position: Vector2) -> void:
	if escoria.main.current_scene.player:
		do_walk(
			position,
			[escoria.main.current_scene.player.global_id, true],
			true
		)
	else:
		escoria.logger.trace(
			self,
			"No player loaded for current scene. Ignoring left double-click on background."
		)


# Called when an element in the scene was focused
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - element_id: Global id of the element focused
func element_focused(element_id: String) -> void:
	pass


# Called when no element is focused anymore
# (Needs to be overridden, if supported)
func element_unfocused() -> void:
	pass


# Called when an item was left clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - item_global_id: Global id of the item that was clicked
# - event: The received input event
func left_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_LEFT_CLICK,
		[item_global_id, event],
		true
	)


# Called when an item was right clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - item_global_id: Global id of the item that was clicked
# - event: The received input event
func right_click_on_item(item_global_id: String, event: InputEvent) -> void:
	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_RIGHT_CLICK,
		[item_global_id, event],
		true
	)


# Called when an item was double clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - item_global_id: Global id of the item that was clicked
# - event: The received input event
func left_double_click_on_item(
	item_global_id: String,
	event: InputEvent
) -> void:
	escoria.action_manager.do(
		escoria.action_manager.ACTION.ITEM_LEFT_CLICK,
		[item_global_id, event],
		true
	)


# Called when an inventory item was left clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - inventory_item_global_id: Global id of the inventory item was clicked
# - event: The received input event
func left_click_on_inventory_item(
	inventory_item_global_id: String,
	event: InputEvent
) -> void:
	pass


# Called when an inventory item was right clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - inventory_item_global_id: Global id of the inventory item was clicked
# - event: The received input event
func right_click_on_inventory_item(
	inventory_item_global_id: String,
	event: InputEvent
) -> void:
	pass


# Called when an inventory item was double clicked
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - inventory_item_global_id: Global id of the inventory item was clicked
# - event: The received input event
func left_double_click_on_inventory_item(
	inventory_item_global_id: String,
	event: InputEvent
) -> void:
	pass


# Called when an inventory item was focused
# (Needs to be overridden, if supported)
#
# #### Parameters
#
# - inventory_item_global_id: Global id of the inventory item that was focused
func inventory_item_focused(inventory_item_global_id: String) -> void:
	pass


# Called when no inventory item is focused anymore
# (Needs to be overridden, if supported)
func inventory_item_unfocused() -> void:
	pass


# Called when the inventory was opened
# (Needs to be overridden, if supported)
func open_inventory():
	pass


# Called when the inventory was closed
# (Needs to be overridden, if supported)
func close_inventory():
	pass


# Called when the mousewheel was used
# (Needs to be overridden, if supported)
#
# #### Parameter
#
# - direction: The direction in which the mouse wheel was rotated
func mousewheel_action(direction: int):
	pass


# Called when the UI should be hidden
# (Needs to be overridden, if supported)
func hide_ui():
	pass


# Called when the UI should be shown
# (Needs to be overridden, if supported)
func show_ui():
	pass


# Set the Editor debug mode
#
# #### Parameter
#
# - p_editor_debug_mode: EDITOR_GAME_DEBUG_DISPLAY enum (int) value
# corresponding to the desired editor debug mode
func _set_editor_debug_mode(p_editor_debug_mode: int) -> void:
	editor_debug_mode = p_editor_debug_mode
	update()


# Automatically called whenever an event is finished. Can be used to reset some
# UI elements to their default/empty state. This function can be called before
# _on_action_finished() if the player input started an event.
# Reimplement to performed desired actions.
#
# #### Parameter
#
# - _return_code: return code of the event (type ESCExecution)
# - _event_name: name of the event that was just done (can be unused)
func _on_event_done(_return_code: int, _event_name: String) -> void:
	pass


# Automatically called whenever an action initiated by the player is finished.
# Can be used to reset some UI elements to their default/empty state.
# Reimplement to performed desired actions.
func _on_action_finished() -> void:
	pass


# Pauses the game. Reimplement to eventually show a specific UI.
func pause_game():
	escoria.set_game_paused(true)


# Unpause the game. Reimplement to eventually hide a specific UI.
func unpause_game():
	escoria.set_game_paused(false)


# Shows the main menu. Reimplement to show a specific UI.
func show_main_menu():
	pass


# Hides the main menu. Reimplement to hide a specific UI.
func hide_main_menu():
	pass


# Custom function that is meant to apply custom settings. Called right after
# Escoria settings file was loaded.
func apply_custom_settings(custom_settings: Dictionary):
	pass


# Custom function automatically called when save game is created.
#
# *Returns* A Dictionary containing the custom data to be saved within the
# game file.
func get_custom_data() -> Dictionary:
	return {}


# Shows the crash popup when a crash occurs
#
# #### Parameters
#
# - files: Array of strings containing the paths to the files generated on crash
func show_crash_popup(files: Array = []) -> void:
	var crash_popup = AcceptDialog.new()
	crash_popup.popup_exclusive = true
	crash_popup.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(crash_popup)
	var files_to_send: String = ""
	for file in files:
		files_to_send += "- %s\n" % file
	crash_popup.dialog_text = tr(ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.CRASH_MESSAGE)
	) % files_to_send
	crash_popup.popup_centered()
	escoria.set_game_paused(true)
	yield(crash_popup, "confirmed")
	emit_signal("crash_popup_confirmed")


# *** FOR USE BY ESCORIA CORE ONLY ***
# Hides everything under the UI Control node.
func escoria_hide_ui():
	if ui_parent_control_node != null and not ui_parent_control_node.is_empty():
		(get_node(ui_parent_control_node) as Control).visible = false
	else:
		escoria.logger.warn(
			self,
			"UI parent Control node not defined!"
		)


# *** FOR USE BY ESCORIA CORE ONLY ***
# Show everything under the UI Control node.
func escoria_show_ui():
	if ui_parent_control_node != null and not ui_parent_control_node.is_empty():
		(get_node(ui_parent_control_node) as Control).visible = true
	else:
		escoria.logger.warn(
			self,
			"UI parent Control node not defined!"
		)


# Manage signal room_deady from main.gd.
func _on_room_ready():
	room_ready_for_inputs = true


# Input function to manage specific input keys.
# Note that if any child of this class wishes to override _input, the overriding
# method MUST call its parent's version (i.e. this method).
func _input(event):
	if escoria.inputs_manager.input_mode == escoria.inputs_manager.INPUT_NONE:
		return

	if event.is_action_pressed("ui_cancel"):
		emit_signal("request_pause_menu")
