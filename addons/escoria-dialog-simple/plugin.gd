# A simple dialog manager for Escoria
tool
extends EditorPlugin


const MANAGER_CLASS="res://addons/escoria-dialog-simple/esc_dialog_simple.gd"


# Register ourselves after setup
func _enter_tree() -> void:
	call_deferred("_register")
	

# Unregister ourselves
func _exit_tree() -> void:
	_unregister()


# Add ourselves to the list of dialog managers
func _register():
	_unregister()
	var dialog_managers: Array = ProjectSettings.get_setting(
		"escoria/ui/dialog_managers"
	)
	dialog_managers.push_back(MANAGER_CLASS)
	ProjectSettings.set_setting(
		"escoria/ui/dialog_managers",
		dialog_managers
	)
	_register_setting(
		"escoria/dialog_simple/avatars_path",
		"",
		{
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	)
	
	_register_setting(
		"escoria/dialog_simple/text_speed_per_character",
		0.1,
		{
			"type": TYPE_REAL
		}
	)
	
	_register_setting(
		"escoria/dialog_simple/fast_text_speed_per_character",
		0.25,
		{
			"type": TYPE_REAL
		}
	)
	
	_register_setting(
		"escoria/dialog_simple/max_time_to_disappear",
		1.0,
		{
			"type": TYPE_REAL
		}
	)
	

# Remove ourselves from the list of dialog managers
func _unregister():
	var dialog_managers = ProjectSettings.get_setting(
		"escoria/ui/dialog_managers"
	)
	
	dialog_managers.erase(MANAGER_CLASS)
	
	ProjectSettings.set_setting(
		"escoria/ui/dialog_managers",
		dialog_managers
	)
	

# Register a new project setting if it hasn't been defined already
#
# #### Parameters
#
# - name: Name of the project setting
# - default: Default value
# - info: Property info for the setting
func _register_setting(name: String, default, info: Dictionary):
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(
			name,
			default
		)
		info.name = name
		ProjectSettings.add_property_info(info)
