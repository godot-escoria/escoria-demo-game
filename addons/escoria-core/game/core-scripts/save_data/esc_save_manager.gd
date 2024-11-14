# Saves and loads savegame and settings files
class_name ESCSaveManager


signal game_is_loading
signal game_finished_loading

# Template for settings filename
const SETTINGS_TEMPLATE: String = "settings.tres"

# Template for savegames filenames
const SAVE_NAME_TEMPLATE: String = "save_%03d.tres"

# Template for crash savegames filenames
const CRASH_SAVE_NAME_TEMPLATE: String = "crash_autosave_%s_%s.tres"


# If true, saving a game is enabled. Else, saving is disabled
var save_enabled: bool = true

# Variable containing the saves folder obtained from Project Settings
var save_folder: String

# Filename of the latest crash savegame file
var crash_savegame_filename: String

# Variable containing the settings folder obtained from Project Settings
var settings_folder: String

# True if escoria is currently loading a savegame. This is used to avoid
# RoomManager to execute room's :setup and :ready events when loading a savegame
var is_loading_game: bool

# ESC commands kept around for references to their command names.
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


# Constructor of ESCSaveManager object.
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


# Return a list of savegames metadata (id, date, name and game version)
func get_saves_list() -> Dictionary:
	var regex = RegEx.new()
	regex.compile("save_(?<slotnumber>[0-9]{3})\\.tres")

	var saves = {}
	var dirsave = Directory.new()
	if dirsave.open(save_folder) == OK:
		dirsave.list_dir_begin(true, true)
		var nextfile = dirsave.get_next()
		while nextfile != "":
			var save_path = save_folder.plus_file(nextfile)
			var file: File = File.new()
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
	return saves


# Returns true whether the savegame identified by id does exist
#
# ## Parameters
# - id: integer suffix of the savegame file
func save_game_exists(id: int) -> bool:
	var save_file_path: String = save_folder.plus_file(SAVE_NAME_TEMPLATE % id)
	var file: File = File.new()
	return file.file_exists(save_file_path)


# Save the current state of the game in a file suffixed with the id value.
# This id can help with slots development for the game developer.
#
# ## Parameters
# - id: integer suffix of the savegame file
# - p_savename: name of the savegame
func save_game(id: int, p_savename: String):
	if not save_enabled:
		escoria.logger.debug(
			self,
			"Save request while saving is not possible. Save cancelled."
		)
		return

	var save_game := _do_save_game(p_savename)

	var directory: Directory = Directory.new()
	if not directory.dir_exists(save_folder):
		directory.make_dir_recursive(save_folder)

	var save_path = save_folder.plus_file(SAVE_NAME_TEMPLATE % id)
	var error: int = ResourceSaver.save(save_path, save_game)
	if error != OK:
		escoria.logger.error(
			self,
			"There was an issue writing savegame number %s to %s." % [id, save_path]
		)


# Performs an emergency savegame in case of crash.
func save_game_crash():
	var datetime = OS.get_datetime()
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
	crash_savegame_filename = save_file_path.plus_file(
		CRASH_SAVE_NAME_TEMPLATE % [
			str(datetime["year"]) + str(datetime["month"])
					+ str(datetime["day"]),
			str(datetime["hour"]) + str(datetime["minute"])
					+ str(datetime["second"])
		]
	)

	var error: int = ResourceSaver.save(crash_savegame_filename, save_game)
	if error != OK:
		escoria.logger.error(
			self,
			"There was an issue writing the crash save to %s."
				% crash_savegame_filename
		)
	return error


# Actual savegame function.
#
# ## Parameters
# - p_savename: name of the savegame
func _do_save_game(p_savename: String) -> ESCSaveGame:
	var save_game = ESCSaveGame.new()

	var plugin_config = ConfigFile.new()
	plugin_config.load("res://addons/escoria-core/plugin.cfg")
	save_game.escoria_version = plugin_config.get_value("plugin", "version")

	save_game.game_version = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_VERSION
	)
	save_game.name = p_savename

	save_game.date = OS.get_datetime()

	escoria.globals_manager.save_game(save_game)
	escoria.inventory_manager.save_game(save_game)
	escoria.object_manager.save_game(save_game)
	escoria.main.save_game(save_game)
	escoria.event_manager.save_game(save_game)
	save_game.settings = escoria.settings_manager.get_settings_dict()
	save_game.custom_data = escoria.game_scene.get_custom_data()

	return save_game


# Load a savegame file from its id.
#
# ## Parameters
# - id: integer suffix of the savegame file
func load_game(id: int):
	var save_file_path: String = save_folder.plus_file(SAVE_NAME_TEMPLATE % id)
	var file: File = File.new()
	if not file.file_exists(save_file_path):
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

	escoria.logger.info(
		self,
		"Loading savegame %s." % str(id)
	)
	is_loading_game = true
	escoria.current_state = escoria.GAME_STATE.LOADING

	var save_game: ESCSaveGame = ResourceLoader.load(save_file_path)

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
	# Hide main and pause menus
	escoria.game_scene.hide_main_menu()
	escoria.game_scene.unpause_game()
	
	escoria.room_manager.change_scene(save_game.main.current_scene_filename, false)

	
	_load_savegame_objects(save_game.objects)
	
	escoria.globals_manager.clear()
	_load_savegame_globals(save_game.globals)
	_load_savegame_inventory(save_game.inventory)
	_load_savegame_terrain_navpolys(save_game.terrain_navpolys)
	
	
	
	
	# 1. Transition
	# 2. Hide main and pause menus
	# 3. Change scene
	# 4. Set all globals
	# 5. Set player inventory
	# 6. Set (rooms) objects
	#		- Sound
	#		- Active/inactive
	#		- Interactive or not
	#		- State
	#		- Position, direction
	# 7. Set Camera
	# 8. Set Navpolys
	# 9. Reschedule schedulded events
	# 10. When load is finished and we're ready to give back control to player
	

	_transition.run(["fade_black", "in", 1.0])
	
	escoria.set_game_paused(false)
	
	escoria.action_manager.clear_current_action()
	escoria.action_manager.clear_current_tool()
	escoria.inputs_manager.input_mode = escoria.inputs_manager.INPUT_ALL
	is_loading_game = false
	escoria.current_state = escoria.GAME_STATE.DEFAULT
	emit_signal("game_finished_loading")


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


func _load_room_objects(room_id: String, objects_dictionary: Dictionary):
	escoria.logger.info(self, "Managing current room %s" % room_id)
	for object_id in objects_dictionary:
		_load_object(object_id, objects_dictionary[object_id], room_id)


func _load_object(object_id: String, object_dictionary: Dictionary, room_id: String):
	escoria.logger.info(self, "Loading object %s" % object_id)
	if object_id == ESCObjectManager.CAMERA:
		_camera_set_target.run([0, object_dictionary["target"]])
	else:
		# Active
		if object_dictionary.has("active"):
			_set_active_if_exists.run([object_id, object_dictionary["active"]])
		
		# Interactive
		if object_dictionary.has("interactive"):
			_set_interactive.run([object_id, object_dictionary["interactive"]])
		
		# State
		if object_dictionary.has("state"):
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
			if not custom_data.empty():
				_set_item_custom_data.run([object_id, custom_data])
			

func _load_savegame_globals(savegame_globals: Dictionary):
	for g in savegame_globals: 
		_set_global.run([g, savegame_globals[g], true])


func _load_savegame_inventory(savegame_inventory: Array):
	for g in savegame_inventory: 
		_add_inventory.run([g, savegame_inventory[g]])


func _load_savegame_terrain_navpolys(savegame_terrain_navpolys: Dictionary):
	for room_id in savegame_terrain_navpolys:
		for terrain_id in savegame_terrain_navpolys[room_id]:
			if savegame_terrain_navpolys[room_id][terrain_id]:
				_enable_terrain.run([terrain_id])
				break
