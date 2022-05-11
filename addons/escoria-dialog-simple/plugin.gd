# A simple dialog manager for Escoria
tool
extends EditorPlugin

const MANAGER_CLASS="res://addons/escoria-dialog-simple/esc_dialog_simple.gd"

# Unregister ourselves
func disable_plugin():
	print("Disabling plugin Escoria Dialog Simple")
	EscoriaPlugin.deregister_dialog_manager(MANAGER_CLASS)


# Add ourselves to the list of dialog managers
func enable_plugin():
	print("Enabling plugin Escoria Dialog Simple")
	EscoriaPlugin.register_dialog_manager(MANAGER_CLASS)
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
