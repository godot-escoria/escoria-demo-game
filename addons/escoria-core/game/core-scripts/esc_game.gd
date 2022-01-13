# A base class for ESC game scenes
# An extending class can be used in the project settings and is responsible
# for managing very basic game features and controls
extends Node2D
class_name ESCGame


# Emitted when the user has confirmed the crash popup
signal crash_popup_confirmed


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


# A reference to the node handling tooltips
var tooltip_node: Object


# Ready function
func _ready():
	escoria.apply_settings(escoria.settings)
	connect("crash_popup_confirmed", escoria, "quit", 
		[], CONNECT_ONESHOT)

# Handle debugging visualizations
func _draw():
	if !Engine.is_editor_hint():
		return
	if editor_debug_mode == EDITOR_GAME_DEBUG_DISPLAY.NONE:
		return
	
	if editor_debug_mode == EDITOR_GAME_DEBUG_DISPLAY.MOUSE_TOOLTIP_LIMITS:
		var mouse_limits: Rect2 = get_viewport_rect().grow(
			-mouse_tooltip_margin
		)
		print(mouse_limits)
		
		# Draw lines for tooltip limits
		draw_rect(mouse_limits, ColorN("red"), false, 10.0)


# Called when the player left clicks on the background
# (Needs to be overridden, if supported)
# 
# #### Parameters
#
# - position: Position clicked
func left_click_on_bg(position: Vector2) -> void:
	escoria.do(
		"walk",
		[escoria.main.current_scene.player.global_id, position],
		true
	)


# Called when the player right clicks on the background
# (Needs to be overridden, if supported)
# 
# #### Parameters
#
# - position: Position clicked	
func right_click_on_bg(position: Vector2) -> void:
	escoria.do(
		"walk", 
		[escoria.main.current_scene.player.global_id, position],
		true
	)


# Called when the player double clicks on the background
# (Needs to be overridden, if supported)
# 
# #### Parameters
#
# - position: Position clicked
func left_double_click_on_bg(position: Vector2) -> void:
	escoria.do(
		"walk", 
		[escoria.main.current_scene.player.global_id, position, true],
		true
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
	escoria.do(
		"item_left_click", 
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
	escoria.do(
		"item_right_click", 
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
	escoria.do(
		"item_left_click", 
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
func _set_editor_debug_mode(p_editor_debug_mode: int) -> void:
	editor_debug_mode = p_editor_debug_mode
	update()


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
	crash_popup.dialog_text = tr(ProjectSettings.get_setting(
		"escoria/debug/crash_message")
	) % files_to_send
	crash_popup.popup_centered()
	escoria.set_game_paused(true)
	yield(crash_popup, "confirmed")
	emit_signal("crash_popup_confirmed")

