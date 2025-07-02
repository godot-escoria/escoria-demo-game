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

## Signal emitted when the state switched to another. Parameter is the next[br]
## state name.
signal finished(next_state_name: String)


## Initialize the state. E.g. change the animation
func enter():
	return


## Clean up the state. Reinitialize values like a timer.
func exit():
	return


## Handle the input event.[br]
## [br]
## #### Parameters[br]
## [br]
## - _event: the input event to handle
func handle_input(_event: InputEvent):
	return


## Update call for states happening in _process() method.[br]
## [br]
## #### Parameters[br]
## [br]
## - _delta: delta value coming from the _process() method.
func update(_delta: float):
	return


## For states managing animations, method called on animation_finished signal.[br]
## [br]
## #### Parameters[br]
## [br]
## - _anim_name: finished animation name.
func _on_animation_finished(_anim_name: String):
	return
