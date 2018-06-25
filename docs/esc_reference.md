General
-------

- Events:
  When the player interacts with an object in the game, the object receives an even. Each event executes a series of commands.
  Events start with the character ":" in the Events file. Example:

```
:use
```

- Groups
  Commands can be grouped using the character ">" to start a group, and incrementing the indentation of the commands that belong to the group. Example:
```
>
	set_global door_open true
	animation player pick_up
# end of group
```

- Global flags
  Global flags define the state of the game, and can have a value of true, false or an integer. All commands or groups can be conditioned to the value of a global flag.

- Conditions
  In order to run a command conditionally dependin on the value of a flag, use [] with a list of conditions. All conditions in the list must be true. The character "!" before a flag can be used to negate it.
  Example:

```
# runs the command only if the door_open flag is true
say player "The door is open" [door_open]
```

```
# runs the group only if door_open is false and i/key is true
> [!door_open,i/key]
	say player "The door is close, maybe I can try this key in my inventory"
```

  Additionally, there's a set of comparison operators for use with global integers: `eq`, `gt` and `lt`, all of which can be negated.
  Example:

```
# runs the command only if the value of pieces_of_eight is greater than 5
set_state inv_pieces_of_eight money_bag [gt pieces_of_eight 5]
```

- Commands
  Commands consist of one word followed by parameters. Parameters can be one word, or strings in quotes. A string can also be preceeded by an ID for localization and the ":" character. Example:

```
# one parameter "player", another parameter "hello world", with id "dialog_hello"
say player dialog_hello:"hello world"
```

- Global IDs
  All objects in the game have a global ID, which is used to identify them in commands. The ID is configured in the object's scene.

- States
  Each object can have a "state". The state is stored in the global state of the game, and the savegame, and it's set on the object when the scene is instanced. States can also be animations with the same name in the object's scene, in that case the animation is run when the state is set.

- Active
  Objects can be active or not active. Non-active objects are hidden and non clickable.

- Blocking
  Some commands will block execution of the event until they finish, others won't. See the command's reference for details on which commands block.

Game global state
-----------------

The following values are saved in the global game state and savegames:

- Global flags
- Object's "state" values
- Object's "active" values
- Object's potisions if moved


Inventory
---------

The inventory is handled as a special case of global flags. All flags with a name starting with "i/" are considered an inventory object, with the object's global id following. Example:

```
# adds the object "key" to the inventory
set_global i/key true
```

```
# removes the object "key" to the inventory
set_global i/key false
```

Command list
------------

- `debug string [string2 ...]`
  Takes 1 or more strings, prints them to the console.

- `set_global name value`
  Changes the value of the global "name" with the value. Value can be "true", "false" or an integer.

- `dec_global name value`
  Subtracts the value from global with given "name". Value and global must both be integers.

- `inc_global name value`
  Adds the value to global with given "name". Value and global must both be integers.

- `set_globals pattern value`
  Changes the value of multiple globals using a wildcard pattern. Example:

```
# clears the inventory
set_globals i/* false
```

- `set_state object state`
  Changes the state of an object, and executes the state animation if present. The command can be used to change the appearance of an item. Please see `cut_scene` for changing costumes for NPCs and the player character.

Items can change state by playing animations from an `AnimationPlayer` named "animation". The `AnimationPlayer` is typically used to change the texture of a `Sprite` node, but it's also possible to add additional tracks for changing the tooltip and other properties of the item scene. By using keyframes and looping, any given state can also use multiple textures to bring more life to the item.

- `set_hud_visible visible`
  If you have a cut-scene-like sequence where the player doesn't have control, and you also have HUD elements visible, use this to hide the HUD. You want to do that because it explicitly signals the player that there is no control over the game at the moment. "visible" is true or false.

- `say object text [type] [avatar]`
  Runs the specified string as a dialog said by the object. Blocks execution until the dialog finishes playing. Optional parameters:
  - "type" determines the type of dialog UI to use. Default value is "default"
  - "avatar" determines the avatar to use for the dialog. Default value is "default"

- `anim object name [reverse] [flip_x] [flip_y]`
  Executes the animation specificed with the "name" parameter on the object, without blocking. The next command in the event will be executed immediately after. Optional parameters:
  - reverse plays the animation in reverse when true
  - flip_x flips the x axis of the object's sprites when true (object's root node needs to be Node2D)
  - flip_y flips the y axis of the object's sprites when true (object's root node needs to be Node2D)

- `cut_scene object name [reverse] [flip_x] [flip_y]`
  Executes the animation specificed with the "name" parameter on the object, blocking. The next command in the event will be executed when the animation is finished playing. Optional parameters:
  - reverse plays the animation in reverse when true
  - flip_x flips the x axis of the object's sprites when true (object's root node needs to be Node2D)
  - flip_y flips the y axis of the object's sprites when true (object's root node needs to be Node2D)

  You must use this to change the appearance of the player character or an item that has an idle animation (think NPCs), and then explicitly `set_state char idle` for the appearance to come into effect.
  An `AnimationPlayer` with the given parameter should be a child of the player node, although one named "animation" is always the fallback when trying set a missing costume.


- `set_active object value`
  Changes the "active" state of the object, value can be true or false. Inactive objects are hidden in the scene.

- `set_use_action_menu object value`
  Sets whether or not an action menu should be used on object. It must use the `item.gd` script. Value can be true or false. Useful for "soft-disabling" objects without removing them by `set_active`.

- `wait seconds`
  Blocks execution of the current script for a number of seconds specified by the "seconds" parameter.

- `change_scene path`
  Loads a new scene, specified by "path"

- `set_speed object speed`
  Sets how fast object moves. It must use the `interactive.gd` script or something extended from it. Value is an integer.

- `teleport object1 object2`
  Sets the position of object1 to the position of object2

- `walk object1 object2`
  Moves object1 towards the position of object2, at the speed determined by object1's "speed" property. This command is non-blocking.

- `walk_block object1 object2`
  Moves object1 towards the position of object2, at the speed determined by object1's "speed" property. This command is blocking.

- `turn_to object degrees`
  Turns `object` to a `degrees` angle with a `directions` animation.
  0 sets `object` facing forward, 90 sets it 90 degrees clockwise ("east") etc. When turning to the destination angle, animations are played if they're defined in `animations`.
  `object` must be player or interactive.
  `degrees` must be between [0, 360] or an error is reported.

- `set_angle object degrees`
  Turns `object` to a `degrees` angle without animations.
  0 sets `object` facing forward, 90 sets it 90 degrees clockwise ("east") etc. When turning to the destination angle, animations are played if they're defined in `animations`.
  `object` must be player or interactive.
  `degrees` must be between [0, 360] or an error is reported.

- `spawn path [object2]`
  Instances a scene determined by "path", and places in the position of object2 (object2 is optional)

- `stop`
  Stops the event's execution.

- `repeat`
  Restarts the execution of the current scope at the start. A scope can be a group or an event.

- `sched_event time object event`
  Schedules the execution of an "event" found in "object" in a time in seconds. If another event is running at the time, execution starts when the running event ends.

- `camera_set_pos speed x y`
  Moves the camera to a position defined by "x" and "y", at the speed defined by "speed" in pixels per second. If speed is 0, camera is teleported to the position.

- `camera_set_target speed object [object2 object3 ...]`
  Configures the camera to follow 1 or more objects, using "speed" as speed limit. This is the default behavior (default follow object is "player"). If there's more than 1 object, the camera follows the average position of all the objects specified.

-`camera_set_zoom magnitude [time]`
  Zooms the camera in/out to the desired magnitude. Values larger than 1 zooms the camera out, and smaller values zooms in, relative to the default value of 1. An optional time in seconds controls how long it takes for the camera to zoom into position.

-`camera_set_zoom_height pixels [time]`
  Similar to the command above, but uses pixel height instead of magnitude to zoom.

- `queue_resource path front_of_queue`
  Queues the load of a resource in a background thread. The path must be a full path inside your game, for example "res://scenes/next_scene.tscn". The "front_of_queue" parameter is optional (default value false), to put the resource in the front of the queue. Queued resources are cleared when a change scene happens (but after the scene is loaded, meaning you can queue resources that belong to the next scene).

- `queue_animation object animation`
  Similar to queue_resource, queues the resources necessary to have an animation loaded on an item. The resource paths are taken from the item placeholders.

- `game_over continue_enabled show_credits`
  Ends the game. Use the "continue_enabled" parameter to enable or disable the continue button in the main menu afterwards. The "show_credits" parameter loads the credits ui if true.

Dialogs
-------

To start a dialog, use the "?" character, with some parameters, followed by a list of dialog options. Each option starts with the "-" character, followed by a parameter with the text to display in the dialog interface. Inside the option, a group of commands is specified using indentation.

Example:

```
# character's "talk" event
:talk
? type avatar timeout timeout_option
	- "I'd like to buy a map." [!player_has_map]
		say player "I'd like to buy a map"
		say map_vendor "Do you know the secret code?"
		?
			- "Uncle Sven sends regards."
				say player "Uncle Sven sends regards."

				>	[player_has_money]
					say map_vendor "Here you go."
					say player "Thanks!"
					inventory_add map
					set_global player_has_map true
					stop

				>	[!player_has_money]
					say map_vendor "You can't afford it"
					say player "I'll be back"
					stop

			- "Nevermind"
				say player "Nevermind"
				stop
	- "Nevermind"
		say player "Nevermind"
		stop
repeat
```

All parameters are options:
 - type: (default value "default") the type of dialog menu to use. All types are in the "dd_player" scene.
 - avatar: (default value "default") the avatar to use in the dialog ui.
 - timeout: (default value 0) timeout to select an option. After the time has passed, the "timeout_option" will be selected automatically. If the value is 0, there's no timeout.
 - timeout_option: (default value 0) option selected when timeout is reached.

