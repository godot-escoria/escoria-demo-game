# A simple dialog manager for Escoria
tool
extends EditorPlugin

const MANAGER_CLASS="res://addons/escoria-dialog-simple/esc_dialog_simple.gd"


# Override function to return the plugin name.
func get_plugin_name():
	return "escoria-dialog-simple"


# Unregister ourselves
func disable_plugin():
	print("Disabling plugin Escoria Dialog Simple")
	ESCProjectSettingsManager.register_setting(
		ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE,
		"",
		{}
	)
	ESCProjectSettingsManager.register_setting(
		ESCProjectSettingsManager.AVATARS_PATH,
		null,
		{}
	)

	ESCProjectSettingsManager.register_setting(
		ESCProjectSettingsManager.TEXT_SPEED_PER_CHARACTER,
		null,
		{}
	)

	ESCProjectSettingsManager.register_setting(
		ESCProjectSettingsManager.FAST_TEXT_SPEED_PER_CHARACTER,
		null,
		{}
	)

	ESCProjectSettingsManager.register_setting(
		ESCProjectSettingsManager.MAX_TIME_TO_DISAPPEAR,
		null,
		{}
	)

	EscoriaPlugin.deregister_dialog_manager(MANAGER_CLASS)


# Add ourselves to the list of dialog managers
func enable_plugin():
	print("Enabling plugin Escoria Dialog Simple")
	if EscoriaPlugin.register_dialog_manager(self, MANAGER_CLASS):
		ESCProjectSettingsManager.register_setting(
			ESCProjectSettingsManager.DEFAULT_DIALOG_TYPE,
			"floating",
			{
				"type": TYPE_STRING
			}
		)
	
		ESCProjectSettingsManager.register_setting(
			ESCProjectSettingsManager.AVATARS_PATH,
			"",
			{
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_DIR
			}
		)

		ESCProjectSettingsManager.register_setting(
			ESCProjectSettingsManager.TEXT_SPEED_PER_CHARACTER,
			0.1,
			{
				"type": TYPE_REAL
			}
		)

		ESCProjectSettingsManager.register_setting(
			ESCProjectSettingsManager.FAST_TEXT_SPEED_PER_CHARACTER,
			0.25,
			{
				"type": TYPE_REAL
			}
		)

		ESCProjectSettingsManager.register_setting(
			ESCProjectSettingsManager.MAX_TIME_TO_DISAPPEAR,
			1.0,
			{
				"type": TYPE_REAL
			}
		)
	else:
		get_editor_interface().set_plugin_enabled(
			get_plugin_name(),
			false
		)
