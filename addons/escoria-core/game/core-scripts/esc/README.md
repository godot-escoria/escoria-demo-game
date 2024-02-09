# Welcome to ASHES!

ASHES (**A**dventure **S**cripting **H**elping **ES**coria) is the language used to make your adventure game come to life.

If you're familiar with languages like Python or GDScript, you should feel right at home using it. If you aren't, don't worry because both Python and GDScript are very beginner-friendly languages!

If you're already familiar with ESCscript from earlier versions of Escoria, much of it is the same in terms of how files and events are laid out, as are the commands available.

# Script Files

ASHES is placed into separate files with the extension `.esc`. These files can then be referenced from specific objects in Escoria, like rooms and inventory items. They're also used to setup and start your game.

These files contain the events that a specific Escoria object can respond to or that are necessary for Escoria to run.

# The Basics
As mentioned above, ASHES borrows heavily from Pythonic languages. If you're new to such languages, it might be a good idea to look into tutorials and/or documentation on Python and/or GDScript. ASHES can almost be considered a "subset" of such languages.

The biggest differences include the following:
- `.esc` files contain one or more "events", existing at the highest level of scope (i.e. has no indentation at all). Events are denoted using `:event` where "event" is the name of the event you wish to implement. Refer to https://docs.escoria-framework.org/en/devel/scripting/z_esc_reference.html#events for more information on events.
- Currently there is no support for user-defined functions. Note that these are different from "events".
- There are some special variable conventions meant to make life a bit easier.
- Global variable scoping can require some care.

# Data Types
ASHES currently recognizes the following data types:
- Integers
- Floats/reals
- Booleans
- Strings

The keyword `nil` is used in place of "null" and/or where empty values are desired.

## Strings
Strings can be concatenated using the `+` operator. Use this to construct dynamic strings that will display the value of a given variable, e.g. 
```
var first_string = "amazing"
var second_string = "This is an " + first_string + " feature!"
```
Quotation marks in a string can be escaped in order to display them as actual output.

# Precedence
Precedence is respected and interpreted in an order similar to Python and GDScript.

# Syntax
ASHES supports the following language features:

## Booleans and Boolean Operators
`true` and `false` are used for Boolean values. 

`not`, `and` and `or` are available as Boolean operators. `not` can also be represented with an exclamation mark, i.e. `!`.

ASHES evaluates "truthiness" similar to how GDScript does. In our case, if a value can be cast to a Boolean, it is and then evaluated.

Boolean evaluations should also "short circuit".

## Arithmetic Operators
|Operation              | Symbol |
|-----------------------|--------|
|Addition               | +      |
|Subtraction		 	| -		 |
|Multiplication			| *	 	 |
|Division				| /		 |

## Comparison Operators
|Operation					| Symbol	|
|---------------------------|-----------|
|Greater than				| >			|
|Greater than or equal		| >=		|
|Less than					| <			|
|Less than or equal			| <=		|
|Equality					| ==		|


## Variables

### Local
Variables can be declared using the `var` keyword, e.g. `var this_variable`.  No types are needed as part of the declaration.

You can also define the value of variables at the time of declaration, e.g. `var this_variable = 1`.

Variables respect scoping rules similar to those of Python and GDScript. A variable is considered to be "local" to the block in which it's declared.

### Global
Global variables can be declared for use across events and even scripts. The `global` keyword exists for this purpose and can be used in place of `var`, e.g. `global important_variable`. Again, no types are needed, and you can also define the value during declaration just as with local variables.

**A Word of Caution**: Because Escoria only executes scripts as they are encountered, the order of execution follows the structure of the scene tree in Godot. That is, an ASHES script attached to a room will be executed before that of a child node. As such, the use of global variables should be closely watched, and it is worth noting that a global variable declaration's initializer (if one exists) will be run every time it is encountered. However, the variable will NOT be "redeclared" and so multiple executions of a line containing a global variable declaration (with or without an initializer) should be safe.

## Comments
Text may be commented by using one (or more) hashtags/pound signs/number signs (i.e. a `#` character). Any text appearing to the right of the `#` sign for the remainder of that particular line will be treated as a comment.

Block comments are not currently supported.

## Branching
ASHES can branch using `if`, `elif`, and `else`. For example:
```
if some_variable or other_variable:
	print("Branch 1")
elif another_variable:
	print("Branch 2")
else:
	print("Branch 3")
```

## Looping
`while` loops are currently the only form of looping supported. For example:

```
while counter_variable < 10:
	print(counter_variable)
```
Loops can be broken out of by using the `break` keyword. Like similar languages, `break` will only exit the innermost loop containing the `break`.

# Language Features
ASHES was created with making scripting adventure games easy. Here is a list of features built in to the language:

## Events
Events remain largely the same as described earlier on this page.

As a reminder:
- If you wish to cease execution of the current event, use the `stop` keyword at any point within the event.
- `pass` can be used in the same way as it is used in GDScript.
- One or more flags can be set (optional) beside the event name. Each one must be preceded by a `|` character. E.g. `:look | NO_UI | NO_TT`

## Global IDs
In Escoria, every important entity is referenced by a global ID assigned by the developer (if you aren't sure where these are found, you can check the inspector panel of an appropriate Escoria node and look for the `Global ID` field).

As you have likely seen, these are strings, and you treat them as strings in ASHES wherever you need to use a global ID, e.g. `if this_object == "object_1_id":`.

To avoid having to always enclose a global ID in quotation marks, you can simply prefix the ID with a `$` character, e.g. `if this_object == $object_1_id`, and Escoria will know you're trying to refer to a global ID.

## Built-in Variables
The following list of variables are always available in script:

|Variable				| Purpose																		|
|-----------------------|-------------------------------------------------------------------------------|
|`CURRENT_PLAYER`		| References the current player scene being used, irrespective of its global ID.|
|`ESC_LAST_SCENE`		| Holds the global ID of the last visited room.									|
|`ESC_CURRENT_SCENE`	| Holds the global ID of the current room.										|
|`FORCE_LAST_SCENE_NULL`| Internal use only.															|
|`ANIMATION_RESOURCES`  | Internal use only.															|

## Inventory
If you want to check whether a particular object is currently in your inventory, you can make use of the `in inventory` feature.

For example: `if $gold_brick in inventory:`

## State Checking
You can check whether a particular `ESCObject` (or derivative) is active by using the `is active` feature, e.g. 
`if $room_monster is active:`

Similarly, you can for a particular state of an `ESCObject` (or derivative) by using the `is` keyword, e.g. `if $room_monster is "running_away":`

# Commands
Built-in commands come from the `commands` directory in `escoria-core`. This makes it easy to create custom commands and be able to instantly use them in your scripts!

Commands are called just as functions normally are, e.g. `say($player, "I'm saying this line!")`

In addition, the `print` command exists to help you debug and otherwise send output to Godot's output window, e.g. `print("The value of this variable is: " + some_variable)`

# Dialogs
A block of dialog begins with `?!` and is scoped the same as any other script; that is, with appropriate indentation. When a corresponding outdent is encountered, the block of dialog is considered finished. 

Blocks can be nested. You can use the `break` keyword to "bust out" of the current level of dialog and Escoria will move up to the previous level, if one exists. If the dialog is already at the top-most level, the `break` will conclude the dialog.

If you need to break out of more than one level, you can specify the number of levels to break out of, e.g. `break 2` will move up two levels of dialog, and, if there aren't that many levels of dialog above the current one, the outermost dialog will be concluded.

Use `done` if you want to conclude the entire dialog from any level of nesting. In other words, if you're 5 levels deep, instead of using `break 5` to  dialog, you can simply use `done`.

Each dialog choice is prefixed with a `-`, for example:
```
- "Why are you here?"
```

Dialog choices can be made to be shown (or hidden) by placing a predicate in square brackets to the immediate right of the dialog choice. Say, for example, you wish to present the dialog choice from the previous point only if the character hasn't already asked this three times:
```
- "Why are you here?" [num_times_asked < 3]
```
 
Script can be placed beneath a dialog choice so that if the corresponding dialog choice is chosen, that script will be executed. The script must be indented and treated like a new block of script.

## Examples
Here is a dialog that takes place between the player and a worker where the player has only one dialog choice:
```
	# Variables declared above here and not shown for brevity
	?!
		- "What is your name?"
			say($current_player, "Who are you?")

			if !name_known:
				say($worker, "I'm the worker")
			else:
				say($worker, "You already asked me that")

			name_known = true

	say($current_player, "This conversation is done!")
```

In this example, the only available dialog choice asks, "What is your name?" Note the indentation of the script that appears after the `?!` marker

On selection of the dialog choice in the game, the player will be made to ask, "Who are you?" Depending on the value of `name_known`, the worker will reply with an appropriate answer, after which the value of `name_known` is updated, so you can imagine the worker giving two different answers depending on whether the player chooses this dialog choice for the first time, or any time subsequent.

Once the dialog is finished, the player will remark, "This conversation is done!".

Here is a slightly more complicated example, showing how dialogs can be nested:

```
	# Variables declared above here and not shown for brevity
	?!
		- "Can I ask you about Loom?" [!loom_conversation_done]
			say("current_player", "What do you know about Loom?")
			say("worker", "What do you want to know about Loom?")
			?!
				- "Could it be created in Escoria?"
					say("player", "Could Loom be created in Escoria?")
					say("worker", "Yes!")
				- "Is it an old game?"
					say("current_player", "Is the game as old as you are?")
					say("worker", "You'd better be kidding...")
					?!
						- "I am."
							say("current_player", "I am. Sorry.")
							break
						- "Not really."
							say("current_player", "Not really.")
							say("current_player", "Let's talk about something else.")
							var break_level = 2
							break break_level
				- "Is it a fun game?"
					say("player", "Is Loom a fun game?")
					say("worker", "Yes!")
					fun_game_asked = true
				- "I don't want to talk at all anymore."
					turn_to("worker", "worker_face_down")
					done
				# This will take you back to the outer set of questions
				- "I know enough about Loom."
					loom_conversation_done = true
					break
```
(Notice that, in this example, instead of using the `$` convention for global IDs, we use an actual string to show that both methods work.)

In this example, the player is engaged in a dialog with a worker, this time potentially inquiring about Loom, depending on the value of `loom_conversation_done`.

We can see that if "Can I ask you about Loom?" is chosen, another level of dialog containing five new options will be displayed, each with its own associated script to execute.

We can also see that if "Is it an old game?" is chosen, it will open up another level of dialog with two new options ("I am." and "Not really.").

If we do end up selecting, "Not really.", the dialog will use the `break` keyword to move up two levels of dialog, i.e. the top-most level. Similarly, if "I know enough about Loom." is selected, it will move up one level of dialog, which happens to be the top-most level.

If "I don't want to talk at all anymore." is chosen, `done` will conclude the entire dialog.

