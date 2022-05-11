class_name EscoriaPlugin


# Register a user interface. This should be called in a deferred way
# from the addon's _enter_tree.
#
# #### Parameters
# - game_scene: Path to the game scene extending ESCGame
static func register_ui(game_scene: String):
	var game_scene_setting_value = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_SCENE
	)

	if not game_scene_setting_value in [
		"",
		game_scene
	]:
		push_error("Can't register user interface because %s is registered"
				% game_scene_setting_value
		)
		return
	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.GAME_SCENE,
		game_scene
	)


# Deregister a user interface
#
# #### Parameters
# - game_scene: Path to the game scene extending ESCGame
static func deregister_ui(game_scene: String):
	var game_scene_setting_value = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.GAME_SCENE
		)

	if game_scene_setting_value != game_scene:
		push_error(
			"Can't deregister user interface %s because it is not registered."
					% game_scene_setting_value
		)
		return
	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.GAME_SCENE,
		""
	)


# Register a dialog manager addon. This should be called in a deferred way
# from the addon's _enter_tree.
#
# #### Parameters
# - manager_class: Path to the manager class script
static func register_dialog_manager(manager_class: String):
	var dialog_managers: Array = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	)

	if manager_class in dialog_managers:
		return

	dialog_managers.push_back(manager_class)

	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS,
		dialog_managers
	)


# Deregister a dialog manager addon
#
# #### Parameters
# - manager_class: Path to the manager class script
static func deregister_dialog_manager(manager_class: String):
	var dialog_managers: Array = ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS
	)

	if not manager_class in dialog_managers:
		push_warning("Dialog manager %s is not registered" % manager_class)
		return

	dialog_managers.erase(manager_class)

	ESCProjectSettingsManager.set_setting(
		ESCProjectSettingsManager.DIALOG_MANAGERS,
		dialog_managers
	)
