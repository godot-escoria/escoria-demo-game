## Saves and loads savegame and settings files.
class_name ESCSaveManager

## Emitted when the game is starting to load a savegame.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
signal game_is_loading

## Emitted when the game has finished loading a savegame.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
signal game_finished_loading

## Template for settings filename.
const SETTINGS_TEMPLATE: String = "settings.tres"

## Template for savegames filenames.
const SAVE_NAME_TEMPLATE: String = "save_%03d.tres"

## Template for crash savegames filenames.
const CRASH_SAVE_NAME_TEMPLATE: String = "crash_autosave_%s_%s.tres"

## If true, saving a game is enabled. Else, saving is disabled.
var save_enabled: bool = true

## Variable containing the saves folder obtained from Project Settings.
var save_folder: String

## Filename of the latest crash savegame file.
var crash_savegame_filename: String

## Variable containing the settings folder obtained from Project Settings.
var settings_folder: String

## True if escoria is currently loading a savegame. This is used to avoid
## RoomManager to execute room's :setup and :ready events when loading a savegame.
var is_loading_game: bool

## ESC commands kept around for references to their command names.
var _add_inventory: InventoryAddCommand
var _transition: TransitionCommand
var _hide_menu: HideMenuCommand
var _camera_set_target: CameraSetTargetCommand
var _change_scene: ChangeSceneCommand
var _enable_terrain: EnableTerrainCommand
var _set_active: SetActiveCommand
var _set_active_if_exists: SetActiveIfExistsCommand
var _set_interactive: SetInteractiveCommand
var _set_item_custom_data: SetItemCustomDataCommand
var _teleport_pos: TeleportPosCommand
var _set_direction: SetDirectionCommand
var _set_global: SetGlobalCommand
var _set_state: SetStateCommand
var _stop_snd: StopSndCommand
var _play_snd: PlaySndCommand
var _sched_event: SchedEventCommand

## Constructor of ESCSaveManager object.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _init():
	# We leave the calls to ProjectSettings as-is since this constructor can be
	# called from escoria.gd's own.
	save_folder = ProjectSettings.get_setting("escoria/main/savegames_path")
	settings_folder = ProjectSettings.get_setting("escoria/main/settings_path")

	_add_inventory = InventoryAddCommand.new()
	_transition = TransitionCommand.new()
	_hide_menu = HideMenuCommand.new()
	_camera_set_target = CameraSetTargetCommand.new()
	_change_scene = ChangeSceneCommand.new()
	_enable_terrain = EnableTerrainCommand.new()
	_set_active = SetActiveCommand.new()
	_set_active_if_exists = SetActiveIfExistsCommand.new()
	_set_interactive = SetInteractiveCommand.new()
	_set_item_custom_data = SetItemCustomDataCommand.new()
	_teleport_pos = TeleportPosCommand.new()
	_set_direction = SetDirectionCommand.new()
	_set_global = SetGlobalCommand.new()
	_set_state = SetStateCommand.new()
	_stop_snd = StopSndCommand.new()
	_play_snd = PlaySndCommand.new()
	_sched_event = SchedEventCommand.new()
	is_loading_game = false

## Return a list of savegames metadata (id, date, name and game version).[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `Dictionary` value. (`Dictionary`)
func get_saves_list() -> Dictionary:
	var regex = RegEx.new()
	regex.compile("save_(?<slotnumber>[0-9]{3})\\.tres")

	var saves = {}

	_ensure_directory_exists(save_folder)

	var dirsave = DirAccess.open(save_folder)

	if dirsave != null:
		dirsave.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var nextfile = dirsave.get_next()
		while nextfile != "":
			var save_path = save_folder.path_join(nextfile)
			var save_game_res: Resource = load(save_path)

			if save_game_res == null:
				escoria.logger.warn(
					self,
					"Savegame file %s is corrupted. Skipping." % save_path
				)
			else:
				var matches = regex.search(nextfile)
				if matches != null and matches.get_string("slotnumber") != null:
					var save_game_data = {
						"date": save_game_res["date"],
						"name": save_game_res["name"],
						"game_version": save_game_res["game_version"],
						"slotnumber": matches.get_string("slotnumber")
					}
					saves[int(matches.get_string("slotnumber"))] = save_game_data
				else:
					escoria.logger.warn(
						self,
						"Savegame file %s contains valid data but doesn't match filename format %s. Skipping."
								% [save_path, regex.get_pattern()]
					)
			nextfile = dirsave.get_next()
	else:
		escoria.logger.error(
			self,
			"Could not open savegame folder %s" % save_folder
		)

	return saves

## True whether the savegame identified by id does exist.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |id|`int`|Integer suffix of the savegame file.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns true whether the savegame identified by id does exist. (`bool`)
func save_game_exists(id: int) -> bool:
	var save_file_path: String = save_folder.path_join(SAVE_NAME_TEMPLATE % id)
	return FileAccess.file_exists(save_file_path)

## Save the current state of the game in a file suffixed with the id value. This id can help with slots development for the game developer.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |id|`int`|Integer suffix of the savegame file.|yes|[br]
## |p_savename|`String`|Name of the savegame.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func save_game(id: int, p_savename: String):
	if not save_enabled:
		escoria.logger.debug(
			self,
			"Saving is currently disabled. Save cancelled."
		)
		return

	var save_game := _do_save_game(p_savename)

	if not DirAccess.dir_exists_absolute(save_folder):
		DirAccess.make_dir_recursive_absolute(save_folder)

	var save_path = save_folder.path_join(SAVE_NAME_TEMPLATE % id)
	var error: int = ResourceSaver.save(save_game, save_path)
	if error != OK:
		escoria.logger.error(
			self,
			"There was an issue writing savegame number %s to %s." % [id, save_path]
		)

## Performs an emergency savegame in case of crash.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `int` value. (`int`)
func save_game_crash() -> int:
	var datetime = Time.get_datetime_dict_from_system()
	var datetime_string = "%02d/%02d/%02d %02d:%02d" % [
		datetime["day"],
		datetime["month"],
		datetime["year"],
		datetime["hour"],
		datetime["minute"],
	]

	var save_game := _do_save_game("Crash %s" % datetime_string)

	var save_file_path: String = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.LOG_FILE_PATH
	)
	crash_savegame_filename = save_file_path.path_join(
		CRASH_SAVE_NAME_TEMPLATE % [
			str(datetime["year"]) + str(datetime["month"])
					+ str(datetime["day"]),
			str(datetime["hour"]) + str(datetime["minute"])
					+ str(datetime["second"])
		]
	)

	var error: int = ResourceSaver.save(save_game, crash_savegame_filename)
	if error != OK:
		escoria.logger.error(
			self,
			"There was an issue writing the crash save to %s."
				% crash_savegame_filename
		)
	return error

## Actual savegame function.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |p_savename|`String`|Name of the savegame.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `ESCSaveGame` value. (`ESCSaveGame`)
func _do_save_game(p_savename: String) -> ESCSaveGame:
	var save_game = ESCSaveGame.new()

	var plugin_config = ConfigFile.new()
	plugin_config.load("res://addons/escoria-core/plugin.cfg")
	save_game.escoria_version = plugin_config.get_value("plugin", "version")

	save_game.game_version = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_VERSION
	)
	save_game.name = p_savename

	save_game.date = Time.get_datetime_dict_from_system()

	escoria.globals_manager.save_game(save_game)
	escoria.inventory_manager.save_game(save_game)
	escoria.object_manager.save_game(save_game)
	escoria.main.save_game(save_game)
	escoria.event_manager.save_game(save_game)
	save_game.settings = escoria.settings_manager.get_settings_dict()
	save_game.custom_data = escoria.game_scene.get_custom_data()

	return save_game

## Load a savegame file from its id.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |id|`int`|Integer suffix of the savegame file.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func load_game(id: int):
	var save_file_path: String = save_folder.path_join(SAVE_NAME_TEMPLATE % id)
	if not FileAccess.file_exists(save_file_path):
		escoria.logger.error(
			self,
			"Save file %s doesn't exist." % save_file_path
		)
		return

	# Disconnect all trigger areas in the current room so that they don't
	# trigger after room is loaded (eg: when player was in a trigger area,
	# trigger_out won't fire after loading the game)
	if (escoria.main.current_scene != null):
		escoria.main.current_scene.get_tree().call_group(escoria.GROUP_ITEM_TRIGGERS, "disconnect_trigger_events")

	emit_signal("game_is_loading")

	# Disconnect all trigger areas in the current room so that they don't
	# trigger after room is loaded (eg: when player was in a trigger area,
	# trigger_out won't fire after loading the game)
	if (escoria.main.current_scene != null):
		escoria.main.current_scene.get_tree().call_group(escoria.GROUP_ITEM_TRIGGERS, "disconnect_trigger_events")

	game_is_loading.emit()

	escoria.logger.info(
		self,
		"Loading savegame %s" % str(id)
	)
	is_loading_game = true
	escoria.current_state = escoria.GAME_STATE.LOADING

	var save_game: ESCSaveGame = ResourceLoader.load(save_file_path)

	escoria.settings_manager.load_settings_from_dict(save_game.settings)

	escoria.settings_manager.load_settings_from_dict(save_game.settings)

	var plugin_config = ConfigFile.new()
	plugin_config.load("res://addons/escoria-core/plugin.cfg")
	var escoria_version = plugin_config.get_value("plugin", "version")

	# Migrate savegame through escoria versions
	if escoria_version != save_game.escoria_version:
		var migration_manager: ESCMigrationManager = ESCMigrationManager.new()
		save_game = migration_manager.migrate(
			save_game,
			save_game.escoria_version,
			escoria_version,
			"res://addons/escoria-core/game/core-scripts/migrations/versions"
		)

	# Migrate savegame through game versions
	if ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.GAME_VERSION
		) != save_game.game_version \
		and ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.GAME_MIGRATION_PATH
		) != "":
		var migration_manager: ESCMigrationManager = ESCMigrationManager.new()
		save_game = migration_manager.migrate(
			save_game,
			save_game.game_version,
			ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.GAME_VERSION
			),
			ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.GAME_MIGRATION_PATH
			)
		)

	escoria.event_manager.interrupt()

	# Now the actual savegame loading happens.
	# Steps:
	# 1. Hide main and pause menus
	# 2. Change the scene to the next room.
	#    This does the out transition from the current scene.
	#    And resets objects lists in various managers so we don't have to reset
	#    them all manually.
	# 3. Load objects for all rooms
	# 4. Clear current globals (in case the loaded room automatically
	#    initializes some - they are loaded anyway)
	#    Load globals
	# 5. Load inventory items
	# 6. Load room's terrain navigation polygons
	# 7. Load events (currently only scheduled events)
	# === At this point we're done loading the saved game and ready to give
	#     back control to the player
	# 8. Transition in
	# 9. Unpause the game
	# 10. Clear current action, tool
	#     Reset input mode to accept input
	#     Reset escoria state
	#     Set save manager "is_loading_game" var to false since we're now done

	# Hide main and pause menus
	escoria.game_scene.hide_main_menu()
	escoria.game_scene.unpause_game()

	escoria.room_manager.change_scene_to_file(save_game.main.current_scene_filename, false)

	_load_savegame_objects(save_game.objects)

	escoria.globals_manager.clear()
	_load_savegame_globals(save_game.globals)
	_load_savegame_inventory(save_game.inventory)
	_load_savegame_terrain_navpolys(save_game.terrain_navpolys)
	_load_savegame_events(save_game.events)
	_transition.run(["", "in", 1.0])

	escoria.set_game_paused(false)

	escoria.action_manager.clear_current_action()
	escoria.action_manager.clear_current_tool()
	escoria.inputs_manager.input_mode = escoria.inputs_manager.INPUT_ALL
	is_loading_game = false
	escoria.current_state = escoria.GAME_STATE.DEFAULT

	emit_signal("game_finished_loading")

	escoria.logger.info(self, "Finished loading savegame %s" % str(id))

## Load all objects saved in a savegame data.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |savegame_objects|`Dictionary`|Dictionary containing saved objects.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _load_savegame_objects(savegame_objects: Dictionary):
	for object_id in savegame_objects:
		var saved_object_data = savegame_objects[object_id]
		if object_id in ESCObjectManager.RESERVED_OBJECTS: # Sound players only atm
			if saved_object_data.has("state") \
					and saved_object_data["state"] in ["off", "default"]:
				_stop_snd.run([object_id])
			else:
				_play_snd.run([saved_object_data["state"], object_id, saved_object_data["playback_position"]])
		else:
			if object_id == escoria.main.current_scene.global_id:
				_load_room_objects(object_id, saved_object_data)

## Load objects saved in a savegame data for a given room.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |room_id|`String`|Id of the room.|yes|[br]
## |objects_dictionary|`Dictionary`|Dictionary containing the objects data.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _load_room_objects(room_id: String, objects_dictionary: Dictionary):
	escoria.logger.info(self, "Loading room '%s'" % room_id)

	for object_id in objects_dictionary:
		_load_object(object_id, objects_dictionary[object_id], room_id)

	escoria.logger.info(self, "Finished loading room '%s'" % room_id)

## Load one object saved in a savegame data.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object_id|`String`|Id of the object.|yes|[br]
## |object_dictionary|`Dictionary`|Dictionary containing the object's data.|yes|[br]
## |room_id|`String`|Id of the room.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _load_object(object_id: String, object_dictionary: Dictionary, room_id: String):
	escoria.logger.info(self, "Loading object '%s'" % object_id)

	if object_id == ESCObjectManager.CAMERA:
		_camera_set_target.run([0, object_dictionary["target"]])
	else:
		# Active
		if object_dictionary.has("active"):
			_set_active_if_exists.run([object_id, object_dictionary["active"]])

		# Interactive
		if object_dictionary.has("interactive") and _set_interactive.validate([object_id, object_dictionary["interactive"]]):
			_set_interactive.run([object_id, object_dictionary["interactive"]])

		# State
		if object_dictionary.has("state") and _set_state.validate([object_id, object_dictionary["state"], true]):
			_set_state.run([object_id, object_dictionary["state"], true])

		# Position
		if object_dictionary.has("global_transform"):
			_teleport_pos.run([
				object_id,
				object_dictionary["global_transform"].origin.x,
				object_dictionary["global_transform"].origin.y
			])

		# Orientation
		if object_dictionary.has("last_dir"):
			_set_direction.run([object_id, int(object_dictionary["last_dir"]), 0.0])

		# Custom data
		if object_dictionary.has("custom"):
			var custom_data: Dictionary = object_dictionary["custom_data"]
			if not custom_data.is_empty():
				_set_item_custom_data.run([object_id, custom_data])

	escoria.logger.info(self, "Finished loading object '%s'" % object_id)

## Load globals from a savegame data.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |savegame_globals|`Dictionary`|Dictionary containing saved globals.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _load_savegame_globals(savegame_globals: Dictionary):
	escoria.logger.info(self, "Loading globals")

	for g in savegame_globals:
		_set_global.run([g, savegame_globals[g], true])

	escoria.logger.info(self, "Finished loading globals")

## Load inventory from a savegame data.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |savegame_inventory|`Array`|Array containing saved inventory items.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _load_savegame_inventory(savegame_inventory: Array):
	escoria.logger.info(self, "Loading inventory")

	for g in savegame_inventory:
		_add_inventory.run([g])

	escoria.logger.info(self, "Finished loading inventory")

## Load terrain navpolys from a savegame data.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |savegame_terrain_navpolys|`Dictionary`|Dictionary containing saved terrain navpolys.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _load_savegame_terrain_navpolys(savegame_terrain_navpolys: Dictionary):
	escoria.logger.info(self, "Loading terrain")

	for room_id in savegame_terrain_navpolys:
		for terrain_id in savegame_terrain_navpolys[room_id]:
			if savegame_terrain_navpolys[room_id][terrain_id]:
				_enable_terrain.run([terrain_id])
				break

	escoria.logger.info(self, "Finished loading terrain")

## Load events from a savegame data.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |savegame_events|`Dictionary`|Dictionary containing saved events.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _load_savegame_events(savegame_events: Dictionary):
	escoria.logger.info(self, "Loading events")

	if savegame_events.has("sched_events") \
			and not savegame_events.sched_events.is_empty():
		escoria.logger.info(self, "Loading scheduled events")
		for sched_event in savegame_events.sched_events:
			var script: ESCScript = \
				escoria.esc_compiler.load_esc_file(
					sched_event.event_filename,
					sched_event.object
				)
			escoria.event_manager.schedule_event(
				script.events[sched_event.event_name],
				sched_event.timeout,
				sched_event.object
			)
		escoria.logger.info(self, "Finished loading scheduled events")

	escoria.logger.info(self, "Finished loading events")

## Ensures the given directory exists, creating it if necessary.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |dir|`String`|Path to the directory to check or create.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _ensure_directory_exists(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(save_folder):
		var return_code = DirAccess.make_dir_absolute(save_folder)

		if return_code != OK:
			escoria.logger.error(
				self,
				"Could not create savegame folder %s" % save_folder
			)
