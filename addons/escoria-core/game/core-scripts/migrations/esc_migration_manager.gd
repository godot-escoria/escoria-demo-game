# Class that handles migrations between different game or escoria versions
extends Object
class_name ESCMigrationManager


# Regular expression that matches a simple semver version string
const VERSION_REGEX = "^(?<major>\\d+)\\.(?<minor>\\d+)\\.(?<patch>\\d+)$"


# Compiled regex
var version_regex: RegEx


func _init() -> void:
	version_regex = RegEx.new()
	version_regex.compile(VERSION_REGEX)


# Migrates the specified savegame from a specified version to another version
# based on a directory of migration scripts.
#
# The migration manager searches for scripts from after the given version up
# to the target version in this directory, loads them and applies the version.
#
# Each migration will return a modified version of the given savegame
func migrate(
	savegame: ESCSaveGame,
	from: String,
	to: String,
	versions_directory: String
) -> ESCSaveGame:
	escoria.logger.info(
		self,
		"Migrating savegame from version %s to version %s." 
				% [from, to]
	)

	var from_info = version_regex.search(from)
	var to_info = version_regex.search(to)

	var wrong_version: bool = false
	if from_info.get_string("major") > to_info.get_string("major"):
		wrong_version = true
	elif from_info.get_string("major") == to_info.get_string("major") and\
			from_info.get_string("minor") > to_info.get_string("minor"):
		wrong_version = true
	elif from_info.get_string("major") == to_info.get_string("major") and\
			from_info.get_string("minor") == to_info.get_string("minor") and\
			from_info.get_string("patch") > to_info.get_string("patch"):
		wrong_version = true

	if wrong_version:
		escoria.logger.error(
			self,
			"Can not migrate savegame from version %s to version %s." +
			" \"To\" version must be later than \"from\" version." 
			% [from, to]
		)

	var versions = _find_versions(versions_directory, from, to)
	versions.sort_custom(self, "_compare_version")
	if versions[0].get_file().get_basename() == from:
		versions.pop_front()

	for version in versions:
		var migration_script = load(version).new()
		if not migration_script is ESCMigration:
			escoria.logger.error(
				self,
				"File %s is not a valid migration script." % version
			)
		escoria.logger.debug(
			self,
			"Migrating savegame to version %s." % version
		)
		(migration_script as ESCMigration).set_savegame(savegame)
		(migration_script as ESCMigration).migrate()
		savegame = (migration_script as ESCMigration).get_savegame()

	return savegame


# Find all fitting version scripts between the given versions in a directory
# and all its subdirectories
#
# #### Parameters
# - directory: Directory to search in
# - from: Start version to check
# - to: End version to check
# **Returns** A list of version scripts
func _find_versions(directory: String, from: String, to: String) -> Array:
	escoria.logger.trace(
		self, 
		"Searching directory %s." % directory
	)
	var versions = []
	var dir = Directory.new()
	dir.open(directory)
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		var version = file_name.get_basename()
		var regex_result = version_regex.search(version)
		if dir.current_is_dir():
			versions += _find_versions(
				directory.plus_file(file_name),
				from,
				to
			)
		elif regex_result and _version_between(version, from, to):
			escoria.logger.trace(
				self,
				"Found compatible savegame migration script for version %s." % version
			)
			versions.append(
				directory.plus_file(file_name)
			)
		file_name = dir.get_next()
	return versions


# Check, whether the given version is >= from and <= to
#
# #### Parameters
# - version: Version to check
# - from: Start version
# - to: End version
# **Returns** Whether the version matches
func _version_between(version: String, from: String, to: String) -> bool:
	var version_info = version_regex.search(version)
	var from_info = version_regex.search(from)
	var to_info = version_regex.search(to)

	if from_info.get_string("major") < version_info.get_string("major") and \
			version_info.get_string("major") < to_info.get_string("major"):
		return true
	elif from_info.get_string("major") == version_info.get_string("major") and \
			from_info.get_string("minor") < version_info.get_string("minor"):
		return true
	elif from_info.get_string("major") == version_info.get_string("major") and \
			from_info.get_string("minor") == \
				version_info.get_string("minor") and \
			from_info.get_string("patch") < version_info.get_string("patch"):
		return true
	elif to_info.get_string("major") == version_info.get_string("major") and \
			to_info.get_string("minor") > version_info.get_string("minor"):
		return true
	elif to_info.get_string("major") == version_info.get_string("major") and \
			to_info.get_string("minor") == version_info.get_string("minor") and\
			to_info.get_string("patch") > version_info.get_string("patch"):
		return true

	return false


# Compare to version strings
#
# #### Parameters
# - version_a: First version to compare
# - version_b: Second version to compare
# **Returns** true when version_b should be sorted after version_a
func _compare_version(version_a: String, version_b: String) -> bool:
	var a_info = version_regex.search(version_a.get_file().get_basename())
	var b_info = version_regex.search(version_b.get_file().get_basename())

	if a_info.get_string("major") < b_info.get_string("major"):
		return true
	elif a_info.get_string("major") == b_info.get_string("major") and \
			a_info.get_string("minor") < b_info.get_string("minor"):
		return true
	elif a_info.get_string("major") == b_info.get_string("major") and \
			a_info.get_string("minor") == b_info.get_string("minor") and \
			a_info.get_string("patch") < b_info.get_string("patch"):
		return true

	return false

