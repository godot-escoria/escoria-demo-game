class_name Migrator4647
extends Node

enum MigrationAction {
	UPGRADE_4_7,
	DOWNGRADE_4_6,
	DO_NOTHING
}

const MIGRATION_DONE = "migration_done"
const GODOT_4_7_HEX = 0x040700


func check_need_upgrade_or_downgrade_scripts(engine_version: Dictionary = Engine.get_version_info()) -> MigrationAction:
	var data: Dictionary = read_migration_file()
	var current_version_hex: int = engine_version["hex"]
	var current_is_4_7_or_newer: bool = current_version_hex >= GODOT_4_7_HEX
	if data.is_empty(): # No existing file : initiate migration
		if current_is_4_7_or_newer:
			return MigrationAction.UPGRADE_4_7
		return MigrationAction.DOWNGRADE_4_6

	if not data[MIGRATION_DONE]:
		if data["last_engine_version_hex"] >= GODOT_4_7_HEX:
			return MigrationAction.UPGRADE_4_7
		return MigrationAction.DOWNGRADE_4_6

	var last_migration_version = data["last_engine_version_hex"]
	var last_is_4_7_or_newer: bool = last_migration_version >= GODOT_4_7_HEX
	if last_is_4_7_or_newer == current_is_4_7_or_newer:
		return MigrationAction.DO_NOTHING
	if last_is_4_7_or_newer:
		return MigrationAction.DOWNGRADE_4_6
	return MigrationAction.UPGRADE_4_7


func prepare_specific_godot_version(target_hex: int) -> void:
	var dir = DirAccess.open("res://addons/escoria-core/game/core-scripts/")
	print("Preparing Escoria for Godot version %s" % [target_hex])
	if dir == null:
		print("Failed opening folder res://addons/escoria-core/game/core-scripts/")
		return

	# Backup existing files, just in case they were edited by gamedev (and so, different from
	# origin).
	var datetime: String = Time.get_datetime_string_from_system().replace(":", ".")
	var res: Error = dir.copy(
		"res://addons/escoria-core/game/core-scripts/esc_item.gd",
		"res://addons/escoria-core/game/core-scripts/pre-4.7/esc_item.gd.%s.bak" % datetime
	)
	if res != OK:
		print("Failed backup of existing file res://addons/escoria-core/game/core-scripts/esc_item.gd")
		return

	# Then remove
	res = dir.remove("res://addons/escoria-core/game/core-scripts/esc_item.gd")
	if res != OK:
		print("Failed removing file res://addons/escoria-core/game/core-scripts/esc_item.gd")
		return

	if target_hex < GODOT_4_7_HEX: # < 4.7.0
		# Copy 4.6 files
		res = DirAccess.copy_absolute(
			"res://addons/escoria-core/game/core-scripts/pre-4.7/esc_item.4.6.gd",
			"res://addons/escoria-core/game/core-scripts/esc_item.gd"
		)
		if res != OK:
			print("Failed copying file res://addons/escoria-core/game/core-scripts/pre-4.7/esc_item.4.6.gd")
			return
	else: # >= 4.7.x
		# Copy 4.7 files
		res = DirAccess.copy_absolute(
			"res://addons/escoria-core/game/core-scripts/pre-4.7/esc_item.4.7.gd",
			"res://addons/escoria-core/game/core-scripts/esc_item.gd"
		)
		if res != OK:
			print("Failed copying file res://addons/escoria-core/game/core-scripts/pre-4.7/esc_item.4.7.gd")
			return

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
	var parsed: Variant = JSON.parse_string(new_last_version_used_file.get_as_text())
	new_last_version_used_file.close()
	if not (parsed is Dictionary):
		push_error("Error reading file res://addons/escoria-core/game/core-scripts/pre-4.7/last_version_used.json")
		return {}
	return parsed
