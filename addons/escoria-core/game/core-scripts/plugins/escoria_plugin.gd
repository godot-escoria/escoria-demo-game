## Base class for Escoria plugins.
class_name EscoriaPlugin

## Register a user interface. This should be called in a deferred way from the addon's _enter_tree.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |plugin|`EditorPlugin`|the plugin that registers|yes|[br]
## |game_scene|`String`|Path to the game scene extending ESCGame|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `bool` value. (`bool`)
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

## Deregister a user interface.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |game_scene|`String`|Path to the game scene extending ESCGame|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
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


## Register a dialog manager addon. This should be called in a deferred way from the addon's _enter_tree.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |plugin|`EditorPlugin`|the plugin that registers|yes|[br]
## |manager_class|`String`|Path to the manager class script|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `bool` value. (`bool`)
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


## Deregister a dialog manager addon.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |manager_class|`String`|Path to the manager class script|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
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
