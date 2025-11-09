## Used by the intpreter to track the depth of a `break` statement invoked in a dialog.
extends Object
class_name ESCBreakCounter


var _levels_left: int = 0:
	set = set_levels_left,
	get = get_levels_left


## Sets the depth from the root of the dialog tree, with `levels == 0` at the root.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |levels|`int`|Number of dialog nesting levels remaining (0 represents the root).|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_levels_left(levels: int) -> void:
	_levels_left = levels


## Gets the depth from the root of the dialog tree, with `levels == 0` at the root.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `int` value. (`int`)
func get_levels_left() -> int:
	return _levels_left


## Decrements by one the depth from the root of the dialog tree, with `levels == 0` at the root.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func dec_levels_left() -> void:
	_levels_left = _levels_left - 1
