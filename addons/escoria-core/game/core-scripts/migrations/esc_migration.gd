## Base class for all migration version scripts. Extending scripts should be
## named like the version they migrate the savegame to. (e.g. 1.0.0.gd, 1.0.1.gd)
extends RefCounted
class_name ESCMigration
## Base class for all migration version scripts. Extending scripts should be
## named like the version they migrate the savegame to. (e.g. 1.0.0.gd, 1.0.1.gd)

## The savegame object to migrate
var _savegame: ESCSaveGame:
	get = get_savegame


## Set the savegame[br]
## [br]
## #### Parameters[br]
## - savegame: Savegame object to modify
func set_savegame(savegame: ESCSaveGame):
	_savegame = savegame


## Get the savegame[br]
## **Returns** The Savegame object
func get_savegame():
	return _savegame


## Override this function in the version script with
## the things that need to be applied to the savegame
func migrate():
	pass
