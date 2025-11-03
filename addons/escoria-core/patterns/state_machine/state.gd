extends Node
class_name State
## Base interface for all states.
## 
## This class doesn't do anything in itself but forces us to pass the right 
## arguments to the methods below and makes sure every State object had all of 
## these methods.

## Signal sent when the state just changed. Parameter is the new state value.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |next_state_name|`Variant`|Name of the state that should become active after this state finishes.|yes|[br]
## [br]
signal finished(next_state_name)


## Initialize the state. E.g. change the animation[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func enter():
	return


## Clean up the state. Reinitialize values like a timer.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func exit():
	return


## Manage an input event while this state is active.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |_event|`InputEvent`|InputEvent to process|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func handle_input(_event: InputEvent):
	return


## Perform an update while this state is active.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |_delta|`float`|float value obtained from a _process() call|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func update(_delta: float):
	return


# Callback called when an animation is finished. 
# [br]
# #### Parameters[br]
# - _anim_name: the animation name that just finished.
func _on_animation_finished(_anim_name: String):
	return
