class_name Migrator4647
extends Node

enum MigrationAction {
	UPGRADE_4_7,
	DOWNGRADE_4_6,
	DO_NOTHING
}

const migration_done = "migration_done"


func check_need_upgrade_or_downgrade_scripts(engine_version: Dictionary = Engine.get_version_info()) -> MigrationAction:
	var data: Dictionary = read_migration_file()
	if data.is_empty(): # No existing file : initiate migration
		print("Failed opening 'last_version_used' file: migration not done.")
		if engine_version.hex >= 0x040700:
			print("Targeting 4.7")
			return MigrationAction.UPGRADE_4_7
		else:
			print("Targeting 4.6")
			return MigrationAction.DOWNGRADE_4_6
	
	if not data[migration_done]:
		if data["last_engine_version_hex"] >= 0x040700:
			print("Targeting 4.7")
			return MigrationAction.UPGRADE_4_7
		else:
			print("Targeting 4.6")
			return MigrationAction.DOWNGRADE_4_6
	else: # Migration was marked as done
		return MigrationAction.DO_NOTHING


func prepare_specific_godot_version(target_hex: int) -> void:
	var dir = DirAccess.open("res://addons/escoria-core/game/core-scripts/")
	print("Preparing Escoria for Godot version %s" % [target_hex])

	# Backup existing files, just in case they were edited by gamedev (and so, different from
	# origin).
	var datetime: String = Time.get_datetime_string_from_system().replace(":",".")
	var res: Error = dir.copy(
		"res://addons/escoria-core/game/core-scripts/esc_item.gd",
		"res://addons/escoria-core/game/core-scripts/pre-4.7/esc_item.gd.%s.bak" % datetime
	)

	# Then remove
	res = dir.remove("res://addons/escoria-core/game/core-scripts/esc_item.gd")

	if target_hex < 0x40700: # < 4.7.0
		# Copy 4.6 files
		res = DirAccess.copy_absolute(
			"res://addons/escoria-core/game/core-scripts/pre-4.7/esc_item.4.6.gd",
			"res://addons/escoria-core/game/core-scripts/esc_item.gd"
		)

	else: # >= 4.7.x
		# Copy 4.7 files
		res = DirAccess.copy_absolute(
			"res://addons/escoria-core/game/core-scripts/pre-4.7/esc_item.4.7.gd",
			"res://addons/escoria-core/game/core-scripts/esc_item.gd"
		)
	
	# Lastly, store the last used engine version in a file
	save_migration_file(true)
	
	EditorInterface.restart_editor()


func save_migration_file(migration_done: bool):
	var new_last_version_used_file = FileAccess.open("res://addons/escoria-core/game/core-scripts/pre-4.7/last_version_used.json", FileAccess.WRITE)
	var version = Engine.get_version_info()
	var data: Dictionary = {
		"last_engine_version": version.string,
		"last_engine_version_hex": version.hex,
		"migration_done": migration_done
	}
	new_last_version_used_file.store_string(JSON.stringify(data))
	new_last_version_used_file.close()


func read_migration_file() -> Dictionary:
	var new_last_version_used_file = FileAccess.open("res://addons/escoria-core/game/core-scripts/pre-4.7/last_version_used.json", FileAccess.READ)
	if new_last_version_used_file == null:
		return {}
	var data: Dictionary = JSON.parse_string(new_last_version_used_file.get_as_text())
	print(data)
	if data == null:
		push_error("Error reading file res://addons/escoria-core/game/core-scripts/pre-4.7/last_version_used.json")
	new_last_version_used_file.close()
	return data
