@tool
class_name AcceptDialogMigrate4647
extends AcceptDialog

@onready var label: Label = $FlowContainer/Label
var migrator: Migrator4647
var required_migration: bool = false


func _ready() -> void:
	add_cancel_button("Cancel")
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)
	
	migrator = Migrator4647.new()
	var action: Migrator4647.MigrationAction = migrator.check_need_upgrade_or_downgrade_scripts()
	match action:
		Migrator4647.MigrationAction.UPGRADE_4_7:
			label.text = """The version of Godot Engine you appear to be running is older 
					than the one this version of Escoria relies on (4.7.x).\n
					Godot Engine 4.6 and 4.7 APIs have some differences in methods that Escoria makes use of.
					Escoria can now automatically revert its impacted core scripts to makes them compatible
					with Godot Engine 4.6.\n
					Here is the list of the impacted files:
					- res://addons/escoria-core/game/core-scripts/esc_item.gd\n
					⚠️IMPORTANT⚠️: the editor will restart after this action is done.\n
					If you wish to let Escoria proceed, choose 'OK'.
					If you wish to upgrade to a newer version of Godot, choose 'Cancel'.
					If you have edited these files for your own needs, you'll need to manually fix them:
					choose 'Cancel' (see README; existing files will be backuped anyway).
					"""
			required_migration = true
		Migrator4647.MigrationAction.DOWNGRADE_4_6:
			label.text = """The version of Godot Engine you appear to be running is newer
					than the one this version of Escoria relies on (4.6.x).\n
					Godot Engine 4.6 and 4.7 APIs have some differences in methods that Escoria makes use of.
					Escoria can now automatically revert its impacted core scripts to makes them compatible
					with Godot Engine 4.7.\n
					Here is the list of the impacted files:
					- res://addons/escoria-core/game/core-scripts/esc_item.gd\n
					⚠️IMPORTANT⚠️: the editor will restart after this action is done.\n
					If you wish to let Escoria proceed, choose 'OK'.
					If you wish to upgrade to a newer version of Godot, choose 'Cancel'.
					If you have edited these files for your own needs, you'll need to manually fix them:
					choose 'Cancel' (see README; existing files will be backuped anyway).
					"""
			required_migration = true

		_:
			required_migration = false

func _on_confirmed():
	migrator.prepare_specific_godot_version(Engine.get_version_info().hex)

func _on_canceled():
	await migrator.save_migration_file($FlowContainer/mark_this_as_done.button_pressed)
