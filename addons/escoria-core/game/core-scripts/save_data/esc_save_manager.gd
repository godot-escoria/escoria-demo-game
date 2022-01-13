# Saves and loads savegame and settings files
class_name ESCSaveManager

# If true, saving a game is enabled. Else, saving is disabled
var save_enabled: bool = true

# Variable containing the saves folder obtained from Project Settings
var save_folder: String

# Filename of the latest crash savegame file
var crash_savegame_filename: String

# Template for savegames filenames
const SAVE_NAME_TEMPLATE: String = "save_%03d.tres"

# Template for crash savegames filenames
const CRASH_SAVE_NAME_TEMPLATE: String = "crash_autosave_%s_%s.tres"

# Variable containing the settings folder obtained from Project Settings
var settings_folder: String

# Template for settings filename
const SETTINGS_TEMPLATE: String = "settings.tres"

# Constructor of ESCSaveManager object.
func _init():
	save_folder = ProjectSettings.get_setting("escoria/main/savegames_path")
	settings_folder = ProjectSettings.get_setting("escoria/main/settings_path")

# Return a list of savegames metadata (id, date, name and game version) 
func get_saves_list() -> Dictionary:
	var regex = RegEx.new()
	regex.compile("save_([0-9]{3})\\.tres")
	
	var saves = {}
	var dirsave = Directory.new()
	if dirsave.open(save_folder) == OK:
		dirsave.list_dir_begin(true, true)
		var nextfile = dirsave.get_next()
		while nextfile != "":
			var save_path = save_folder.plus_file(nextfile)
			var file: File = File.new()
			var save_game_res: Resource = load(save_path)
			var save_game_data = {
				"date": save_game_res["date"],
				"name": save_game_res["name"],
				"game_version": save_game_res["game_version"],
			}
			
			var id: int
			var matches = regex.search(nextfile)
			if matches.strings.size() > 1:
				id = int(matches.strings[1])
			
			saves[id] = save_game_data
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
			"esc_save_data_resources.gd",
			["Save requested while saving is not possible. Save canceled."])
		return
	
	var save_game := _do_save_game(p_savename)

	var directory: Directory = Directory.new()
	if not directory.dir_exists(save_folder):
		directory.make_dir_recursive(save_folder)

	var save_path = save_folder.plus_file(SAVE_NAME_TEMPLATE % id)
	var error: int = ResourceSaver.save(save_path, save_game)
	if error != OK:
		escoria.logger.report_errors(
			"esc_save_data_resources.gd",
			["There was an issue writing the save %s to %s" % [id, save_path]]
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
	
	var save_file_path: String = ProjectSettings.get_setting(
		"escoria/debug/log_file_path"
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
		escoria.logger.report_errors(
			"esc_save_data_resources.gd",
			["There was an issue writing the crash save to %s" 
				% crash_savegame_filename])
	return error


# Actual savegame function. 
#
# ## Parameters
# - p_savename: name of the savegame
func _do_save_game(p_savename: String) -> ESCSaveGame:
	var save_game = ESCSaveGame.new()
	save_game.escoria_version = escoria.ESCORIA_VERSION
	save_game.game_version = ProjectSettings.get_setting(
		"escoria/main/game_version"
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
		escoria.logger.report_errors(
			"esc_save_manager.gd:load_game()",
			["Save file %s doesn't exist" % save_file_path])
		return

	escoria.logger.info(
		"esc_save_manager.gd:load_game()",
		["Loading savegame %s" % str(id)])
	
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
	
	if ProjectSettings.get_setting("escoria/main/game_version") != \
			save_game.game_version and \
			ProjectSettings.get_setting(
				"escoria/main/game_migration_path"
			) != "":
		var migration_manager: ESCMigrationManager = ESCMigrationManager.new()
		save_game = migration_manager.migrate(
			save_game,
			save_game.game_version,
			ProjectSettings.get_setting("escoria/main/game_version"),
			ProjectSettings.get_setting(
				"escoria/main/game_migration_path"
			)
		)
	
	escoria.event_manager.interrupt_running_event()

	var load_event = ESCEvent.new(":load")
	var load_statements = []
	
	load_statements.append(
		ESCCommand.new(
			"transition %s out" % 
			[ProjectSettings.get_setting("escoria/ui/default_transition")]
		)
	)
	load_statements.append(
		ESCCommand.new("hide_menu main")
	)
	load_statements.append(
		ESCCommand.new("hide_menu pause")
	)
	
	## GLOBALS
	for k in save_game.globals.keys():
		escoria.globals_manager.set_global(
			k,
			save_game.globals[k],
			true
		)
		
	## ROOM
	load_statements.append(
		ESCCommand.new("change_scene %s false" \
				% save_game.main["current_scene_filename"])
	)
	
	## OBJECTS
	for object_global_id in save_game.objects.keys():
		if escoria.object_manager.has(object_global_id) and \
				save_game.objects[object_global_id].has("active"):
			load_statements.append(ESCCommand.new("set_active %s %s" \
				% [object_global_id, 
				save_game.objects[object_global_id]["active"]])
			)
		
		if save_game.objects[object_global_id].has("interactive"):
			load_statements.append(ESCCommand.new("set_interactive %s %s" \
					% [object_global_id,
				save_game.objects[object_global_id]["interactive"]])
			)
			
		if save_game.objects[object_global_id].has("state"):
			load_statements.append(ESCCommand.new("set_state %s %s true" \
					% [object_global_id,
				save_game.objects[object_global_id]["state"]])
			)
			
		if save_game.objects[object_global_id].has("global_transform"):
			load_statements.append(ESCCommand.new("teleport_pos %s %s %s" \
					% [object_global_id, 
				int(save_game.objects[object_global_id] \
						["global_transform"].origin.x),
				int(save_game.objects[object_global_id] \
						["global_transform"].origin.y)]
				)
			)
			load_statements.append(ESCCommand.new("set_angle %s %s" \
					% [object_global_id, 
				save_game.objects[object_global_id]["last_deg"]])
			)
		
		if object_global_id in ["_music", "_sound", "_speech"]:
			if save_game.objects[object_global_id]["state"] in [
				"default", 
				"off"
			]:
				load_statements.append(
					ESCCommand.new("stop_snd %s" % [
						object_global_id,
					])
				)
			else:
				load_statements.append(
					ESCCommand.new("play_snd %s %s" % [
						save_game.objects[object_global_id]["state"],
						object_global_id,
					])
				)
	
	load_statements.append(
		ESCCommand.new(
			"transition %s in" % 
			[ProjectSettings.get_setting("escoria/ui/default_transition")]
		)
	)
	
	load_event.statements = load_statements
	
	escoria.set_game_paused(false)
	
	escoria.event_manager.queue_event(load_event)
	escoria.logger.debug(
		"esc_save_manager.gd:load_game()",
		["Load event queued."])
	
	
# Save the game settings in the settings file.
func save_settings():
	var settings_res := ESCSaveSettings.new()
	settings_res.escoria_version = escoria.ESCORIA_VERSION
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
		escoria.logger.report_errors(
			"esc_save_data_resources.gd:save_settings()",
			["There was an issue writing settings %s" % save_path])

# Load the game settings from the settings file
# **Returns** The Resource structure loaded from settings file
func load_settings() -> Resource:
	var save_settings_path: String = \
			settings_folder.plus_file(SETTINGS_TEMPLATE)
	var file: File = File.new()
	if not file.file_exists(save_settings_path):
		escoria.logger.report_warnings(
			"esc_save_data_resources.gd:load_settings()",
			["Settings file %s doesn't exist" % save_settings_path,
			"Setting default settings."])
		save_settings()

	return load(save_settings_path)
