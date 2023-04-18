# A simple dialog manager for Escoria
tool
extends EditorPlugin




# Override function to return the plugin name.
func get_plugin_name():
	return "escoria-dialog-simple"


# Unregister ourselves
func disable_plugin():
	print("Disabling plugin Escoria Dialog Simple")
	ESCProjectSettingsManager.remove_setting(
		ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogPluginConstants.AVATARS_PATH
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogPluginConstants.TEXT_TIME_PER_LETTER_MS
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogPluginConstants.TEXT_TIME_PER_LETTER_MS_FAST
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogPluginConstants.CLEAR_TEXT_BY_CLICK_ONLY
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogPluginConstants.READING_SPEED_IN_WPM
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogPluginConstants.LEFT_CLICK_ACTION
	)

	ESCProjectSettingsManager.remove_setting(
		SimpleDialogPluginConstants.STOP_TALKING_ANIMATION_ON
	)

	EscoriaPlugin.deregister_dialog_manager(SimpleDialogPluginConstants.MANAGER_CLASS)


# Add ourselves to the list of dialog managers
func enable_plugin():
	print("Enabling plugin Escoria Dialog Simple")

	if EscoriaPlugin.register_dialog_manager(self, SimpleDialogPluginConstants.MANAGER_CLASS):
		ESCProjectSettingsManager.register_setting(
			ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE,
			"floating",
			{
				"type": TYPE_STRING
			}
		)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogPluginConstants.AVATARS_PATH,
			"res://game/dialog_avatars",
			{
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_DIR
			}
		)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogPluginConstants.TEXT_TIME_PER_LETTER_MS,
			SimpleDialogPluginConstants.TEXT_TIME_PER_LETTER_MS_DEFAULT_VALUE,
			{
				"type": TYPE_REAL
			}
		)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogPluginConstants.TEXT_TIME_PER_LETTER_MS_FAST,
			SimpleDialogPluginConstants.TEXT_TIME_PER_LETTER_MS_FAST_DEFAULT_VALUE,
			{
				"type": TYPE_REAL
			}
		)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogPluginConstants.CLEAR_TEXT_BY_CLICK_ONLY,
			false,
			{
				"type": TYPE_BOOL
			}
		)

		ESCProjectSettingsManager.register_setting(
			SimpleDialogPluginConstants.READING_SPEED_IN_WPM,
			SimpleDialogPluginConstants.READING_SPEED_IN_WPM_DEFAULT_VALUE,
			{
				"type": TYPE_INT
			}
		)

		var left_click_actions_string: String = \
				SimpleDialogPluginConstants.left_click_actions.join(",")

		ESCProjectSettingsManager.register_setting(
			SimpleDialogPluginConstants.LEFT_CLICK_ACTION,
			SimpleDialogPluginConstants.LEFT_CLICK_ACTION_SPEED_UP,
			{
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": left_click_actions_string
			}
		)

		var stop_talking_animation_on_options_string: String = \
				SimpleDialogPluginConstants.stop_talking_animation_on_options.join(",")

		ESCProjectSettingsManager.register_setting(
			SimpleDialogPluginConstants.STOP_TALKING_ANIMATION_ON,
			SimpleDialogPluginConstants.STOP_TALKING_ANIMATION_ON_END_OF_AUDIO,
			{
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": stop_talking_animation_on_options_string
			}
		)

	else:
		get_editor_interface().set_plugin_enabled(
			get_plugin_name(),
			false
		)
