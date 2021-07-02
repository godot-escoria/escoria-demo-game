# Saves and loads savegame and settings files
class_name ESCSaveManager

# Variable containing the saves folder obtained from Project Settings
var save_folder: String

# Template for savegames filenames
const SAVE_NAME_TEMPLATE: String = "save_%03d.tres"

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
	var save_game := ESCSaveGame.new()
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

	var directory: Directory = Directory.new()
	if not directory.dir_exists(save_folder):
		directory.make_dir_recursive(save_folder)

	var save_path = save_folder.plus_file(SAVE_NAME_TEMPLATE % id)
	var error: int = ResourceSaver.save(save_path, save_game)
	if error != OK:
		escoria.logger.report_errors(
			"esc_save_data_resources.gd",
			["There was an issue writing the save %s to %s" % [id, save_path]])

# Load a savegame file from its id.
#
# ## Parameters
# - id: integer suffix of the savegame file
func load_game(id: int):
	var save_file_path: String = save_folder.plus_file(SAVE_NAME_TEMPLATE % id)
	var file: File = File.new()
	if not file.file_exists(save_file_path):
		escoria.logger.report_errors(
			"esc_save_data_resources.gd",
			["Save file %s doesn't exist" % save_file_path])
		return

	var save_game: Resource = ResourceLoader.load(save_file_path)

	var load_event = ESCEvent.new(":load")
	var load_statements = []
	
	## GLOBALS
	for k in save_game.globals.keys():
		load_statements.append(
			ESCCommand.new("set_global %s \"%s\"\n" \
				% [k, save_game.globals[k]])
		)
	
	## ROOM
	load_statements.append(
		ESCCommand.new("change_scene %s true" \
			% save_game.main["current_scene_filename"])
	)
	
	## OBJECTS
	for object_global_id in save_game.objects.keys():
		if save_game.objects[object_global_id].has("active"):
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
				save_game.objects[object_global_id] \
					["global_transform"].origin.x,
				save_game.objects[object_global_id] \
					["global_transform"].origin.y])
			)
			load_statements.append(ESCCommand.new("set_angle %s %s" \
				% [object_global_id, 
				save_game.objects[object_global_id]["last_deg"]])
			)
	
	load_event.statements = load_statements
	escoria.event_manager.queue_event(load_event)
	
	
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
	settings_res.voice_volume = escoria.settings.voice_volume
	settings_res.fullscreen = escoria.settings.fullscreen
	settings_res.skip_dialog = escoria.settings.skip_dialog
	settings_res.rate_shown = escoria.settings.rate_shown

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
func load_settings():
	var save_settings_path: String = settings_folder.plus_file(SETTINGS_TEMPLATE)
	var file: File = File.new()
	if not file.file_exists(save_settings_path):
		escoria.logger.report_warnings(
			"esc_save_data_resources.gd:load_settings()",
			["Settings file %s doesn't exist" % save_settings_path,
			"Setting default settings."])
		save_settings()
		return

	var settings_resource: Resource = load(save_settings_path)
	escoria._on_settings_loaded(settings_resource)
