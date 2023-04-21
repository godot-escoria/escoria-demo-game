# The escoria main script
tool
extends Node
class_name Escoria

# Signal sent when pause menu has to be displayed
signal request_pause_menu


# Name of the Escoria core plugin
const ESCORIA_CORE_PLUGIN_NAME: String = "escoria-core"


# The main scene
onready var main = $main



func _init():
	escoria.inventory_manager = ESCInventoryManager.new()
	escoria.action_manager = ESCActionManager.new()
	escoria.event_manager = ESCEventManager.new()
	escoria.globals_manager = ESCGlobalsManager.new()
	add_child(escoria.event_manager)
	escoria.object_manager = ESCObjectManager.new()
	escoria.command_registry = ESCCommandRegistry.new()
	escoria.resource_cache = ESCResourceCache.new()
	escoria.save_manager = ESCSaveManager.new()
	escoria.inputs_manager = ESCInputsManager.new()
	escoria.settings_manager = ESCSettingsManager.new()

	if ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_SCENE
	).empty():
		escoria.logger.error(
			self,
			"Project setting '%s' is not set!" % ESCProjectSettingsManager.GAME_SCENE
		)
	else:
		escoria.game_scene = escoria.resource_cache.get_resource(
			ESCProjectSettingsManager.get_setting(ESCProjectSettingsManager.GAME_SCENE)
		).instance()


# Load settings
func _ready():
	add_child(escoria.resource_cache)

	_handle_direct_scene_run()

	escoria.settings_manager.load_settings()
	escoria.settings_manager.apply_settings()

	escoria.room_manager.register_reserved_globals()
	escoria.inputs_manager.register_core()

	if ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_START_SCRIPT
	).empty():
		escoria.logger.error(
			self,
			"Project setting '%s' is not set!"
					% ESCProjectSettingsManager.GAME_START_SCRIPT
		)
	escoria.start_script = escoria.esc_compiler.load_esc_file(
		ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.GAME_START_SCRIPT
		)
	)

	if ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.ACTION_DEFAULT_SCRIPT
	).empty():
		escoria.logger.info(
			self,
			"Project setting '%s' is not set. No action defaults will be used."
					% ESCProjectSettingsManager.ACTION_DEFAULT_SCRIPT
		)
	else:
		escoria.action_default_script = escoria.esc_compiler.load_esc_file(
			ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.ACTION_DEFAULT_SCRIPT
			)
		)

	escoria.main = main

	_perform_plugins_checks()


# Verifies that the game is configured with required plugin(s).
# If a required plugin is missing (or disabled) we stop immediately.
func _perform_plugins_checks():
	if ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	).empty():
		escoria.logger.error(
			self,
			"No dialog manager configured. Please add a dialog manager plugin."
		)


# Manage notifications received from OS
#
# #### Parameters
# - what: the notification constant received (usually defined in MainLoop)
func _notification(what: int):
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			escoria.logger.close_logs()
			escoria.is_quitting = true
			get_tree().quit()
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
			escoria.logger.close_logs()
			escoria.is_quitting = true
			get_tree().quit()


# Called by Escoria's main_scene as very very first event EVER.
# Usually you'll want to show some logos animations before spawning the main
# menu in the escoria/main/game_start_script 's :init event
func init():
	# Don't show the UI until we're ready in order to avoid a sometimes-noticeable
	# blink. The UI will be "shown" later via a visibility update to the first room.
	escoria.game_scene.escoria_hide_ui()
	run_event_from_script(escoria.start_script, escoria.event_manager.EVENT_INIT)
	pass


# Input function to manage specific input keys
#
# #### Parameters
# - event: the input event to manage.
func _input(event: InputEvent):
	if InputMap.has_action(ESCInputsManager.ESC_SHOW_DEBUG_PROMPT) \
			and event.is_action_pressed(ESCInputsManager.ESC_SHOW_DEBUG_PROMPT):
		main.get_node("layers/debug_layer/esc_prompt_popup").popup()

	if event.is_action_pressed("ui_cancel"):
		emit_signal("request_pause_menu")
	pass


# Runs the event "event_name" from the "script" ESC script.
#
# #### Parameters
# - script: ESC script containing the event to run. The script must have been
# loaded.
# - event_name: Name of the event to run
func run_event_from_script(script: ESCScript, event_name: String):
	if script == null:
		escoria.logger.error(
			self,
			"Requested action %s on unloaded script %s." % [event_name, script] +
			"Please load the ESC script using esc_compiler.load_esc_file()."
		)
	escoria.event_manager.queue_event(script.events[event_name])
	var rc = yield(escoria.event_manager, "event_finished")
	while rc[1] != event_name:
		rc = yield(escoria.event_manager, "event_finished")

	if rc[0] != ESCExecution.RC_OK:
		escoria.logger.error(
			self,
			"Start event of the start script returned unsuccessful: %d." % rc[0]
		)
		return


# Called from escoria autoload to start a new game.
func new_game():
	escoria.game_scene.escoria_show_ui()
	run_event_from_script(escoria.start_script, escoria.event_manager.EVENT_NEW_GAME)


# Function called to quit the game.
func quit():
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)


# Handle anything necessary if the game started a scene directly.
func _handle_direct_scene_run() -> void:
	if escoria.is_direct_room_run:
		escoria.object_manager.set_current_room(get_tree().get_current_scene())


# Used by game.gd to determine whether the game scene is ready to take inputs
# from the _input() function. To do so, the current_scene must be set, the game
# scene must be set, and the game scene must've been notified that the room
# is ready.
#
# *Returns*
# true if game scene is ready for inputs
func is_ready_for_inputs() -> bool:
	return main.current_scene and main.current_scene.game \
			and main.current_scene.game.room_ready_for_inputs
