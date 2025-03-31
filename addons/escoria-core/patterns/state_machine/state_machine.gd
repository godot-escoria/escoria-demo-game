extends Node
class_name StateMachine
## Base interface for a generic state machine
## It handles initializing, setting the machine active or not
## delegating _physics_process, _input calls to the State nodes,
## and changing the current/active state.

## Signal emitted when the state has changed. Parameter is the new current state.
signal state_changed(current_state)

## Starting state. This node has to be set *before* the initialize(START_STATE)
## command is called.
var START_STATE: Node

## List of states
var states_map = {}

## Stack of states
var states_stack = []  # can also be used as a pushdown automaton

## Value of the current state
var current_state = null

## Name of the current state
var current_state_name = ""

## Whether the state machine is currently enabled or not.
var _active = false: 
	set = set_active


## Initialize the state machine with the start_state parameter.
##
## #### Parameters
##
## - start_state: State value to use as starting state for the state machine.
func initialize(start_state: State):
	if START_STATE == null:
		escoria.logger.error(
			self, 
			"Starting state is required to be initialized with a defined state, 
			but it is null. Escoria cannot determine which of the defined states 
			(in states_map dictionary) is supposed to be the starting one. 
			Please assign a state to START_STATE in your implementation of the StateMachine class.")
	for child in get_children():
		child.connect("finished", Callable(self, "_change_state"))

	set_active(true)
	states_stack.push_front(start_state)
	current_state = states_stack[0]
	current_state.enter()


## Enable or disable the state machine.
##
## #### Parameters
##
## - value: if true, enables the state machine. If false, disables it.
func set_active(value: bool):
	_active = value
	set_physics_process(value)
	set_process_input(value)
	if not _active:
		states_stack = []
		current_state = null


# Manage an input event by the state machine's current state.
#
# #### Parameters
#
# - event: InputEvent to manage.
func _input(event: InputEvent):
	current_state.handle_input(event)


# Lets the state machine's current state perform an update during 
# _physics_process() phase.
#
# #### Parameters
#
# - delta: float value corresponding to the elapsed time since last frame update.
func _physics_process(delta: float):
	current_state.update(delta)


# Lets the state machine's current state perform an action on animation_finished 
# signal.
#
# #### Parameters
#
# - anim_name: name of the animation that finished.
func _on_animation_finished(anim_name: String):
	if not _active:
		return
	current_state._on_animation_finished(anim_name)


# Change the current state of the state machine using its name. The value of 
# the state to be set is obtained in states_map dictionary.
#
# #### Parameters
#
# - state_name: name of the state to set.
func _change_state(state_name: String):
	if not _active:
		return

	escoria.logger.trace(
		self,
		"Dialog State Machine: Changing state from '%s' to '%s'." % [current_state_name, state_name]
	)

	current_state.exit()

	if state_name == "previous":
		states_stack.pop_front()
	else:
		states_stack[0] = states_map[state_name]

	current_state = states_stack[0]

	state_changed.emit(current_state)

	#if state_name != "previous":
	current_state.enter()

	current_state_name = state_name
