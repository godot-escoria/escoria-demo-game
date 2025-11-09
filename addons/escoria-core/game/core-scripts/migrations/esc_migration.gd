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
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |savegame|`ESCSaveGame`|Savegame to modify|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_savegame(savegame: ESCSaveGame):
	_savegame = savegame


## Get the savegame.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `ESCSaveGame` value. (`ESCSaveGame`)
func get_savegame() -> ESCSaveGame:
	return _savegame


## Override this function in the version script with the things that need to be applied to the savegame[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func migrate():
	pass
