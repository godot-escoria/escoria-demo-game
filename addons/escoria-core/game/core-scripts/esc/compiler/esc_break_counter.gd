## Used by the intpreter to track dialog `break` propagation state.
extends Object
class_name ESCBreakCounter


var _levels_left: int = 0:
	set = set_levels_left,
	get = get_levels_left
var _resume_parent_dialog: bool = false


## Sets the remaining number of dialog levels to unwind before control should return to a parent dialog, where `levels == 0` means the unwind has reached the parent dialog that should resume.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |levels|`int`|Number of dialog nesting levels still to exit before resuming a parent dialog.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func set_levels_left(levels: int) -> void:
	_levels_left = levels


## Gets the remaining number of dialog levels to unwind before control should return to a parent dialog, where `levels == 0` means the unwind has reached the parent dialog that should resume.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns an `int` value.
func get_levels_left() -> int:
	return _levels_left


## Returns whether more dialog levels still need to be exited before reaching the parent dialog that should resume.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns `true` if additional dialog levels must still be unwound, otherwise `false`. (`bool`)
func has_levels_left() -> bool:
	return _levels_left > 0


## Advances the dialog-break state upward by one dialog level.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func advance_up_one_level() -> void:
	if _levels_left > 0:
		_levels_left -= 1

	if _levels_left == 0:
		_resume_parent_dialog = true


## Marks the dialog-break state so the receiving dialog frame resumes its own option loop instead of concluding.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func mark_resume_parent_dialog() -> void:
	_resume_parent_dialog = true


## Returns whether the receiving dialog frame should resume its option loop.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns `true` if the parent dialog should resume, otherwise `false`. (`bool`)
func should_resume_parent_dialog() -> bool:
	return _resume_parent_dialog


## Clears the resume-parent-dialog state after it has been consumed by a dialog frame.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func consume_parent_resume() -> void:
	_resume_parent_dialog = false
