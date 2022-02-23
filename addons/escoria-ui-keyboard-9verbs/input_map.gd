const ACTION_SET_VERB_OPEN = "set_action_verb_open"
const ACTION_SET_VERB_PICKUP = "set_action_verb_pickup"
const ACTION_SET_VERB_PUSH = "set_action_verb_push"
const ACTION_SET_VERB_CLOSE = "set_action_verb_close"
const ACTION_SET_VERB_LOOK = "set_action_verb_look"
const ACTION_SET_VERB_PULL = "set_action_verb_pull"
const ACTION_SET_VERB_GIVE = "set_action_verb_give"
const ACTION_SET_VERB_USE = "set_action_verb_use"
const ACTION_SET_VERB_TALK = "set_action_verb_talk"

"""
The keyboard shortcuts are chosen to match the geometric layout in the
9verb UI (example below assumes QWERTY, but implementation should work
for non-QWERTY, as well):

```
open  | pickup | push  ->  Q | W | E
close | look   | pull  ->  A | S | D
give  | use    | talk  ->  Z | X | C
```
"""


# Implemented as an array of arrays rather than a dict because dict
# does not have an items() method to enumerate entries together:
# https://github.com/godotengine/godot-proposals/issues/1965
const action_to_scancode = [
	[ACTION_SET_VERB_OPEN, KEY_Q],
	[ACTION_SET_VERB_PICKUP, KEY_W],
	[ACTION_SET_VERB_PUSH, KEY_E],

	[ACTION_SET_VERB_CLOSE, KEY_A],
	[ACTION_SET_VERB_LOOK, KEY_S],
	[ACTION_SET_VERB_PULL, KEY_D],

	[ACTION_SET_VERB_GIVE, KEY_Z],
	[ACTION_SET_VERB_USE, KEY_X],
	[ACTION_SET_VERB_TALK, KEY_C],
]


static func add_actions_to_input_map() -> void:
	for entry in action_to_scancode:
		var action = entry[0]
		var scancode = entry[1]
		var event = InputEventKey.new()
		# Based on https://github.com/godotengine/godot/pull/18020,
		# `physical_scancode` seems like a more appropriate property than
		# `scancode` in order to support non-QWERTY keyboard layouts while
		# preserving the geometric pattern of the shortcuts.
		event.physical_scancode = scancode
		InputMap.add_action(action)
		InputMap.action_add_event(action, event)


static func erase_actions_from_input_map() -> void:
	for entry in action_to_scancode:
		var action = entry[0]
		InputMap.action_erase_events(action)
		InputMap.erase_action(action)
