# Saves and loads savegame and settings files
class_name ESCSaveManager


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

# ESC commands kept around for references to their command names.
var _transition: TransitionCommand
var _hide_menu: HideMenuCommand
var _change_scene: ChangeSceneCommand
var _set_active: SetActiveCommand
var _set_active_if_exists: SetActiveIfExistsCommand
var _set_interactive: SetInteractiveCommand
var _teleport_pos: TeleportPosCommand
var _set_angle: SetAngleCommand
var _set_global: SetGlobalCommand
var _set_state: SetStateCommand
var _stop_snd: StopSndCommand
var _play_snd: PlaySndCommand


# Constructor of ESCSaveManager object.
func _init():
	# We leave the calls to ProjectSettings as-is since this constructor can be
	# called from escoria.gd's own.
	save_folder = ProjectSettings.get_setting("escoria/main/savegames_path")
	settings_folder = ProjectSettings.get_setting("escoria/main/settings_path")

	_transition = TransitionCommand.new()
	_hide_menu = HideMenuCommand.new()
	_change_scene = ChangeSceneCommand.new()
	_set_active = SetActiveCommand.new()
	_set_active_if_exists = SetActiveIfExistsCommand.new()
	_set_interactive = SetInteractiveCommand.new()
	_teleport_pos = TeleportPosCommand.new()
	_set_angle = SetAngleCommand.new()
	_set_global = SetGlobalCommand.new()
	_set_state = SetStateCommand.new()
	_stop_snd = StopSndCommand.new()
	_play_snd = PlaySndCommand.new()


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
				var save_game_data = {
					"date": save_game_res["date"],
					"name": save_game_res["name"],
					"game_version": save_game_res["game_version"],
				}

				var matches = regex.search(nextfile)
				if matches != null and matches.get_string("slotnumber") != null:
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

	var datetime = OS.get_datetime()
	var datetime_string = "%02d/%02d/%02d %02d:%02d" % [
		datetime["day"],
		datetime["month"],
		datetime["year"],
		datetime["hour"],
		datetime["minute"],
	]
	save_game.date = datetime_string

	escoria.globals_manager.save_game(save_game)
	escoria.object_manager.save_game(save_game)
	escoria.main.save_game(save_game)
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

	escoria.logger.info(
		self,
		"Loading savegame %s." % str(id)
	)

	var save_game: ESCSaveGame = ResourceLoader.load(save_file_path)

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

	var load_event = ESCEvent.new("%s%s" % [ESCEvent.PREFIX, escoria.event_manager.EVENT_LOAD])
	var load_statements = []

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

		load_statements.append(
			ESCCommand.new("%s %s %s true" %
				[
					_set_global.get_command_name(),
					k,
					global_value
				]
			)
		)

	## OBJECTS
	for object_global_id in save_game.objects.keys():
		if save_game.objects[object_global_id].has("active"):
			load_statements.append(ESCCommand.new("%s %s %s" \
					% [
						_set_active_if_exists.get_command_name(),
						object_global_id,
						save_game.objects[object_global_id]["active"]
					]
				)
			)

		if save_game.objects[object_global_id].has("interactive"):
			load_statements.append(ESCCommand.new("%s %s %s" \
					% [
						_set_interactive.get_command_name(),
						object_global_id,
						save_game.objects[object_global_id]["interactive"]
					]
				)
			)

		if save_game.objects[object_global_id].has("state"):
			load_statements.append(ESCCommand.new("%s %s %s true" \
					% [
						_set_state.get_command_name(),
						object_global_id,
						save_game.objects[object_global_id]["state"]
					]
				)
			)

		if save_game.objects[object_global_id].has("global_transform"):
			load_statements.append(ESCCommand.new("%s %s %s %s" \
					% [
						_teleport_pos.get_command_name(),
						object_global_id,
						int(save_game.objects[object_global_id] \
							["global_transform"].origin.x),
						int(save_game.objects[object_global_id] \
							["global_transform"].origin.y)
					]
				)
			)
			load_statements.append(ESCCommand.new("%s %s %s" \
					% [
						_set_angle.get_command_name(),
						object_global_id,
						save_game.objects[object_global_id]["last_deg"]
					]
				)
			)

		if object_global_id in [
				escoria.object_manager.MUSIC,
				escoria.object_manager.SOUND, escoria.object_manager.SPEECH
			]:
			if save_game.objects[object_global_id]["state"] in [
				"default",
				"off"
			]:
				load_statements.append(
					ESCCommand.new("%s %s" % [
						_stop_snd.get_command_name(),
						object_global_id,
					])
				)
			else:
				load_statements.append(
					ESCCommand.new("%s %s %s" % [
						_play_snd.get_command_name(),
						save_game.objects[object_global_id]["state"],
						object_global_id,
					])
				)

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

	load_event.statements = load_statements

	escoria.set_game_paused(false)

	escoria.event_manager.queue_event(load_event)
	escoria.logger.debug(self, "Load event queued.")


# Save the game settings in the settings file.
func save_settings():
	var settings_res := ESCSaveSettings.new()
	var plugin_config = ConfigFile.new()
	plugin_config.load("res://addons/escoria-core/plugin.cfg")

	settings_res.escoria_version = plugin_config.get_value("plugin", "version")
	settings_res.text_lang = escoria.settings.text_lang
	settings_res.voice_lang = escoria.settings.voice_lang
	settings_res.speech_enabled = escoria.settings.speech_enabled
	settings_res.master_volume = escoria.settings.master_volume
	settings_res.music_volume = escoria.settings.music_volume
	settings_res.sfx_volume = escoria.settings.sfx_volume
	settings_res.speech_volume = escoria.settings.speech_volume
	settings_res.fullscreen = escoria.settings.fullscreen
	settings_res.skip_dialog = escoria.settings.skip_dialog
	settings_res.custom_settings = escoria.settings.custom_settings

	var directory: Directory = Directory.new()
	if not directory.dir_exists(settings_folder):
		directory.make_dir_recursive(settings_folder)

	var save_path = settings_folder.plus_file(SETTINGS_TEMPLATE)
	var error: int = ResourceSaver.save(save_path, settings_res)
	if error != OK:
		escoria.logger.error(
			"esc_save_manager.gd:save_settings()",
			["There was an issue writing settings file %s." % save_path])


# Load the game settings from the settings file
# **Returns** The Resource structure loaded from settings file
func load_settings() -> Resource:
	var save_settings_path: String = \
			settings_folder.plus_file(SETTINGS_TEMPLATE)
	var file: File = File.new()
	if not file.file_exists(save_settings_path):
		escoria.logger.warn(
			self,
			"Settings file %s doesn't exist. Using default settings."
					% save_settings_path
		)
		save_settings()

	return load(save_settings_path)
