# Base class for all migration version scripts. Extending scripts should be
# named like the version they migrate the savegame to. (e.g. 1.0.0.gd, 1.0.1.gd)
extends Node
class_name ESCMigration


var _savegame: ESCSaveGame


# Set the savegame
#
# #### Parameters
# - savegame: Savegame to modify
func set_savegame(savegame: ESCSaveGame):
	_savegame = savegame
	

# Get the savegame
# **Returns** Savegame
func get_savegame():
	return _savegame
	

# Override this function in the version script with
# the things that need to be applied to the savegame
func migrate():
	pass
