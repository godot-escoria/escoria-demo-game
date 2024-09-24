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
var _set_angle: SetAngleCommand
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
	_set_angle = SetAngleCommand.new()
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
			"Save requested while saving is not possible. Save cancelled."
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

	var load_event: ESCEvent = ESCEvent.new("%s%s" % [ESCEvent.PREFIX, escoria.event_manager.EVENT_LOAD])
	var load_statements: Array = []

	load_statements.append(
		ESCCommand.new(
			"%s %s out" %
			[
				_transition.get_command_name(),
				ESCProjectSettingsManager.get_setting(
					ESCProjectSettingsManager.DEFAULT_TRANSITION
			)]
		)
	)
	load_statements.append(
		ESCCommand.new("%s main" % _hide_menu.get_command_name())
	)
	load_statements.append(
		ESCCommand.new("%s pause" % _hide_menu.get_command_name())
	)

	## ROOM
	load_statements.append(
		ESCCommand.new("%s %s false" %
				[
					_change_scene.get_command_name(),
					save_game.main["current_scene_filename"]
				]
			)
	)

	## GLOBALS
	for k in save_game.globals.keys():
		var global_value = save_game.globals[k]

		if global_value is String and global_value.empty():
			global_value = "''"
		
		if not k.begins_with("i/"):
			load_statements.append(
				ESCCommand.new("%s %s %s true" %
					[
						_set_global.get_command_name(),
						k,
						"\"%s\"" % [global_value] if (global_value is String) else global_value # If global_value is a string ensure it is treated as such
					]
				)
			)
	
	# INVENTORY
	for item_name in save_game.inventory:
		load_statements.append(
			ESCCommand.new("%s %s" %
				[
					_add_inventory.get_command_name(),
					item_name
				]
			)
		)
		
	## OBJECTS
	var camera_target_to_follow
	
	for room_id in save_game.objects.keys():
		
		var room_objects: Array = save_game.objects[room_id].keys()
		
		if room_id in ESCObjectManager.RESERVED_OBJECTS:
			
			if save_game.objects[room_id]["state"] in [
				"default",
				"off"
			]:
				load_statements.append(
					ESCCommand.new("%s %s" % [
						_stop_snd.get_command_name(),
						room_id,
					])
				)
			else:
				load_statements.append(
					ESCCommand.new("%s %s %s %s" % [
						_play_snd.get_command_name(),
						save_game.objects[room_id]["state"],
						room_id,
						save_game.objects[room_id]["playback_position"]
					])
				)
				
				
		else:
			if room_id == save_game.main.last_scene_global_id:
			
				for object_global_id in save_game.objects[room_id].keys():
					
					if save_game.objects[room_id][object_global_id].has("active"):
						load_statements.append(ESCCommand.new("%s %s %s" \
								% [
									_set_active_if_exists.get_command_name(),
									object_global_id,
									save_game.objects[room_id][object_global_id]["active"]
								]
							)
						)

					if save_game.objects[room_id][object_global_id].has("interactive"):
						load_statements.append(ESCCommand.new("%s %s %s" \
								% [
									_set_interactive.get_command_name(),
									object_global_id,
									save_game.objects[room_id][object_global_id]["interactive"]
								]
							)
						)
					
					if not save_game.objects[room_id][object_global_id]["state"].empty():
						if save_game.objects[room_id][object_global_id].has("state"):
							load_statements.append(ESCCommand.new("%s %s %s true" \
									% [
										_set_state.get_command_name(),
										object_global_id,
										save_game.objects[room_id][object_global_id]["state"]
									]
								)
							)

					if save_game.objects[room_id][object_global_id].has("global_transform"):
						load_statements.append(ESCCommand.new("%s %s %s %s" \
								% [
									_teleport_pos.get_command_name(),
									object_global_id,
									int(save_game.objects[room_id][object_global_id] \
										["global_transform"].origin.x),
									int(save_game.objects[room_id][object_global_id] \
										["global_transform"].origin.y)
								]
							)
						)
						load_statements.append(ESCCommand.new("%s %s %s" \
								% [
									_set_direction.get_command_name(),
									object_global_id,
									save_game.objects[room_id][object_global_id]["last_dir"]
								]
							)
						)

					if save_game.objects[room_id][object_global_id].has("custom_data"):
						var custom_data = save_game.objects[room_id][object_global_id]["custom_data"]
						if custom_data.size() > 0:
							load_statements.append(
								ESCCommand.new(
									"",
									_set_item_custom_data.get_command_name(),
									[
										object_global_id,
										custom_data
									]
								)
							)

					if object_global_id == escoria.object_manager.CAMERA:
						camera_target_to_follow = save_game.objects[room_id][object_global_id]["target"]
					

	## TERRAIN NAVPOLYS
	for room_name in save_game.terrain_navpolys.keys():
		for terrain_name in save_game.terrain_navpolys[room_name]:
			if save_game.terrain_navpolys[room_name][terrain_name]:
				load_statements.append(ESCCommand.new("%s %s" \
						% [
							_enable_terrain.get_command_name(),
							terrain_name
						]
					)
				)
				break
		
	## SCHEDULED EVENTS
	if save_game.events.has("sched_events") \
			and not save_game.events.sched_events.empty():
		escoria.event_manager.set_scheduled_events_from_savegame(
				save_game.events.sched_events)

	## TRANSITION
	load_statements.append(
		ESCCommand.new(
			"%s %s in" %
			[
				_transition.get_command_name(),
				ESCProjectSettingsManager.get_setting(
				ESCProjectSettingsManager.DEFAULT_TRANSITION
			)]
		)
	)
	
	# FOLLOW TARGET
	load_statements.append(
#					ESCCommand.new("%s %s %s %s" % [
			ESCCommand.new("%s %s %s" % [
				_camera_set_target.get_command_name(),
				0,
				camera_target_to_follow
			])
		)
	
	## MAIN
	escoria.main.last_scene_global_id = save_game.main.last_scene_global_id

	load_event.statements = load_statements
	
	escoria.set_game_paused(false)
	
	# Prepare for loading.
	escoria.globals_manager.clear()
	escoria.action_manager.clear_current_action()
	escoria.action_manager.clear_current_tool()
	
	# Resume ongoing event, if there was one
	if save_game.events.has("running_event") \
			and not save_game.events.running_event.empty():
		escoria.event_manager.set_running_event_from_savegame(
				save_game.events.running_event)
	
	# This is the end: Queue the load game event as first in the queue
	escoria.event_manager.queue_event(load_event, false, true)
	escoria.logger.debug(self, "Load event queued.")
