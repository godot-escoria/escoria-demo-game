## Base interface for all states: it doesn't do anything in itself[br]
## but forces us to pass the right arguments to the methods below[br]
## and makes sure every State object had all of these methods.
extends Node
class_name State
## Base interface for all states.
## 
## This class doesn't do anything in itself but forces us to pass the right 
## arguments to the methods below and makes sure every State object had all of 
## these methods.

## Signal sent when the state just changed. Parameter is the new state value.
signal finished(next_state_name)


## Initialize the state. E.g. change the animation
func enter():
	return


## Clean up the state. Reinitialize values like a timer.
func exit():
	return


## Manage an input event while this state is active.[br]
## [br]
## #### Parameters[br]
## - _event: InputEvent to process
func handle_input(_event):
	return


## Perform an update while this state is active.[br]
## [br]
## #### Parameters[br]
## - _delta: float value obtained from a _process() call
func update(_delta):
	return


# Callback called when an animation is finished. 
# [br]
# #### Parameters[br]
# - _anim_name: the animation name that just finished.
func _on_animation_finished(_anim_name):
	return
