@tool
extends Node
class_name Escoria
## The main Escoria script.


## Signal sent when pause menu has to be displayed
signal request_pause_menu


## Name of the Escoria core plugin
const ESCORIA_CORE_PLUGIN_NAME: String = "escoria-core"


## The main scene
@onready var main = $main


# Called by Save Manager signal "game_is_loading" when a savegame is being loaded. 
func _on_game_is_loading():
	escoria.logger.info(self, "SAVEGAME IS LOADING")


# Called by Save Manager signal "game_finished_loading" when a savegame has loaded. 
func _on_game_finished_loading():
	escoria.logger.info(self, "SAVEGAME FINISHED LOADING")


# Constructor. Inits all Escoria's managers accessible from `escoria` Godot global.
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

	escoria.save_manager.game_is_loading.connect(_on_game_is_loading)
	escoria.save_manager.game_finished_loading.connect(_on_game_finished_loading)

	escoria.inputs_manager = ESCInputsManager.new()
	escoria.settings_manager = ESCSettingsManager.new()
	escoria.interpreter_factory = preload("res://addons/escoria-core/game/core-scripts/esc/compiler/esc_interpreter_factory.gd").new()

	if ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_SCENE
	).is_empty():
		escoria.logger.error(
			self,
			"Project setting '%s' is not set!" % ESCProjectSettingsManager.GAME_SCENE
		)
	else:
		escoria.game_scene = escoria.resource_cache.get_resource(
			ESCProjectSettingsManager.get_setting(ESCProjectSettingsManager.GAME_SCENE)
		).instantiate()


# Ready method. Loads settings and Escoria's start script (ESC or ASH).
func _ready():
	add_child(escoria.resource_cache)

	_handle_direct_scene_run()

	escoria.settings_manager.load_settings()
	escoria.settings_manager.apply_settings()

	escoria.room_manager.register_reserved_globals()
	escoria.inputs_manager.register_core()

	if ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_START_SCRIPT
	).is_empty():
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
	).is_empty():
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
	).is_empty():
		escoria.logger.error(
			self,
			"No dialog manager configured. Please add a dialog manager plugin."
		)


# Manage notifications received from OS.
#
# #### Parameters
# - what: the notification constant received (usually defined in MainLoop)
func _notification(what: int):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			escoria.logger.close_logs()
			escoria.is_quitting = true
			get_tree().quit()


## Initializer called by Escoria's main_scene as very very first event EVER.
## Usually you'll want to show some logos animations before spawning the main
## menu in the escoria/main/game_start_script 's `:init` event
func init():
	# Don't show the UI until we're ready in order to avoid a sometimes-noticeable
	# blink. The UI will be "shown" later via a visibility update to the first room.
	escoria.game_scene.escoria_hide_ui()
	run_event_from_script(escoria.start_script, escoria.event_manager.EVENT_INIT)


# Input function to manage specific input keys
#
# #### Parameters
# - event: the input event to manage.
func _input(event: InputEvent):
	if InputMap.has_action(ESCInputsManager.ESC_SHOW_DEBUG_PROMPT) \
			and event.is_action_pressed(ESCInputsManager.ESC_SHOW_DEBUG_PROMPT):
		main.get_node("layers/debug_layer/esc_prompt_popup").popup()

	if event.is_action_pressed("ui_cancel"):
		request_pause_menu.emit()
	pass


## Runs the event "event_name" from the "script" ESC script.[br]
##[br]
## #### Parameters[br]
## - script: ESC script containing the event to run. The script must have been
## loaded.[br]
## - event_name: Name of the event to run
func run_event_from_script(script: ESCScript, event_name: String, from_statement_id: int = 0):
	if script == null:
		escoria.logger.error(
			self,
			"Requested event %s on unloaded script %s." % [event_name, script] +
			"Please load the ESC script using esc_compiler.load_esc_file()."
		)

	if not _event_exists_in_script(script, event_name):
		return

	escoria.event_manager.queue_event(script.events[event_name])
	var rc = await escoria.event_manager.event_finished
	while rc[1] != event_name:
		rc = await escoria.event_manager.event_finished

	if rc[0] != ESCExecution.RC_OK:
		escoria.logger.error(
			self,
			"Start event of the start script returned unsuccessful: %d." % rc[0]
		)
		return


# Checks for the existence of both mandatory and optional events within a specified script.
#
# #### Parameters
# - script: The script in which to check for the existence of the given event.
# - event_name: The name of the event to check for inside the given script.
#
# *Returns*
# True iff event_name exists within script. Method will terminate execution of the program
# if the specified event is required and doesn't exist.
func _event_exists_in_script(script: ESCScript, event_name: String) -> bool:
	if script.events.has(event_name):
		return true

	if  event_name in escoria.event_manager.REQUIRED_EVENTS:
		if script.filename:
			escoria.logger.error(
				self,
				"The script '%s' is missing a required event: '%s'." % [script.filename, event_name]
			)
		else:
			escoria.logger.error(
				self,
				"The required event '%s' requested by internal script is missing." % event_name
			)
	else:
		if script.filename:
			escoria.logger.warn(
				self,
				"The script '%s' is missing the requested event: '%s'." % [script.filename, event_name]
			)
		else:
			escoria.logger.warn(
				self,
				"The event '%s' requested by internal script is missing." % event_name
			)

	return false


## Called from escoria autoload to start a new game.
func new_game():
	escoria.game_scene.escoria_show_ui()
	escoria.globals_manager.clear()
	escoria.main.clear_previous_scene()
	escoria.creating_new_game = true
	escoria.globals_manager.set_global(
			escoria.room_manager.GLOBAL_FORCE_LAST_SCENE_NULL,
			true,
			true
		)
	escoria.event_manager.interrupt()
	run_event_from_script(escoria.start_script, escoria.event_manager.EVENT_NEW_GAME)


## Function called to quit the game.
func quit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


# Handle anything necessary if the game started a scene directly.
func _handle_direct_scene_run() -> void:
	var current_scene: Node = get_tree().get_current_scene()
	if escoria.is_direct_room_run and current_scene is ESCRoom:
		escoria.object_manager.set_current_room(current_scene)


## Used by game.gd to determine whether the game scene is ready to take inputs
## from the _input() function. To do so, the current_scene must be set, the game
## scene must be set, and the game scene must've been notified that the room
## is ready.[br]
##[br]
## *Returns* true if game scene is ready for inputs
func is_ready_for_inputs() -> bool:
	return main.current_scene and main.current_scene.game \
			and main.current_scene.game.room_ready_for_inputs
