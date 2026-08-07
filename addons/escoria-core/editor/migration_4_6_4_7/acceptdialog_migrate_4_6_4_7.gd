@tool
class_name AcceptDialogMigrate4647
extends Window

signal confirmed
signal canceled

var migrator: Migrator4647
var required_migration: bool = false

@onready var label: Label = $FlowContainer/Label
@onready var mark_this_as_done: CheckButton = $FlowContainer/mark_this_as_done
@onready var confirm_button: Button = $FlowContainer/HBoxContainer/confirm
@onready var cancel_button: Button = $FlowContainer/HBoxContainer/cancel


func _ready() -> void:
	migrator = Migrator4647.new()
	var action: Migrator4647.MigrationAction = migrator.check_need_upgrade_or_downgrade_scripts()
	match action:
		Migrator4647.MigrationAction.UPGRADE_4_7:
			title = "Auto-upgrade Escoria-core scripts for Godot Engine 4.7.x"
			label.text = \
"""The version of Godot Engine you appear to be running is newer
than the one this version of Escoria relies on (4.6.x) or this is the first time
you run this version of Escoria.\n
Godot Engine 4.6 and 4.7 APIs have some differences in methods that Escoria makes use of.
Escoria can now automatically revert its impacted core scripts to makes them compatible
with Godot Engine 4.7.\n
Here is the list of the impacted files:
- res://addons/escoria-core/game/core-scripts/esc_item.gd\n
⚠️IMPORTANT⚠️: the editor will restart after this action is done.\n
If you wish to let Escoria proceed, choose 'OK'.
If you wish to upgrade to a newer version of Godot, choose 'Cancel'.
If you have edited these files for your own needs, you'll need to manually fix them:
choose 'Cancel' (see README; existing files will be backuped anyway)."""
			required_migration = true
		Migrator4647.MigrationAction.DOWNGRADE_4_6:
			title = "Auto-downgrade Escoria-core scripts for Godot Engine 4.6.x"
			label.text = \
"""The version of Godot Engine you appear to be running is older
than the one this version of Escoria relies on (4.7.x) or this is the first time
you run this version of Escoria.\n
Godot Engine 4.6 and 4.7 APIs have some differences in methods that Escoria makes use of.
Escoria can now automatically revert its impacted core scripts to makes them compatible
with Godot Engine 4.6.\n
Here is the list of the impacted files:
- res://addons/escoria-core/game/core-scripts/esc_item.gd\n
⚠️IMPORTANT⚠️: the editor will restart after this action is done.\n
If you wish to let Escoria proceed, choose 'OK' (a backup of the existing file will be created).
If you wish to upgrade to a newer version of Godot, choose 'Cancel' (nothing will be done,
but this tool will happen next time you open the editor).
If you have edited these files for your own needs, you'll need to manually fix them:
choose 'Cancel' (see README; existing files will be backuped anyway)."""
			required_migration = true

		_:
			required_migration = false


func _on_confirm_pressed() -> void:
	if mark_this_as_done.button_pressed:
		await migrator.save_migration_file($FlowContainer/mark_this_as_done.button_pressed)
	else:
		migrator.prepare_specific_godot_version(Engine.get_version_info().hex)
	confirmed.emit()
	hide()


func _on_cancel_pressed() -> void:
	await migrator.save_migration_file($FlowContainer/mark_this_as_done.button_pressed)
	canceled.emit()
	hide()


func _on_mark_this_as_done_toggled(toggled_on: bool) -> void:
	if toggled_on:
		cancel_button.hide()
	else:
		cancel_button.show()
