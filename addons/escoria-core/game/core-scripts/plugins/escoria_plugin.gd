class_name EscoriaPlugin

# Register a user interface. This should be called in a deferred way
# from the addon's _enter_tree.
#
# #### Parameters
# - plugin: the plugin that registers
# - game_scene: Path to the game scene extending ESCGame
#
# *Returns* a boolean indicating whether the ui could be successfully registered
static func register_ui(plugin: EditorPlugin, game_scene: String) -> bool:
	if not plugin.get_editor_interface().is_plugin_enabled(
		Escoria.ESCORIA_CORE_PLUGIN_NAME
	):
		push_error("Escoria Core must be enabled.")
		return false
	
	var game_scene_setting_value = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_SCENE
	)

	if not game_scene_setting_value in [
		"",
		game_scene
	]:
		push_error("Can't register user interface because user interface %s is registered."
				% game_scene_setting_value
		)
		return false
	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.GAME_SCENE,
		game_scene
	)
	return true

# Deregister a user interface
#
# #### Parameters
# - game_scene: Path to the game scene extending ESCGame
static func deregister_ui(game_scene: String):
	# If the currently configured game scene is not the one we're disabling, exit now.
	if ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_SCENE
	) != game_scene:
		return

	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.GAME_SCENE,
		""
	)


# Register a dialog manager addon. This should be called in a deferred way
# from the addon's _enter_tree.
#
# #### Parameters
# - plugin: the plugin that registers
# - manager_class: Path to the manager class script
#
# *Returns* a boolean value indicating whether the dialog manager was registered
static func register_dialog_manager(plugin: EditorPlugin, manager_class: String) -> bool:
	if not plugin.get_editor_interface().is_plugin_enabled(
		Escoria.ESCORIA_CORE_PLUGIN_NAME
	):
		push_error("Escoria Core must be enabled.")
		return false
	
	var dialog_managers: Array = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	)

	if manager_class in dialog_managers:
		return true

	dialog_managers.push_back(manager_class)

	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS,
		dialog_managers
	)
	
	return true

# Deregister a dialog manager addon
#
# #### Parameters
# - manager_class: Path to the manager class script
static func deregister_dialog_manager(manager_class: String):
	var dialog_managers: Array = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	)

	# If the dialog manager we're removing in not in the registered list, return quietly.
	if not manager_class in dialog_managers:
		return

	dialog_managers.erase(manager_class)

	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS,
		dialog_managers
	)
