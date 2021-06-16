<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# esc\_compiler.gd

**Extends:** [Node](../Node)

## Description

ESC compiler

The workflow is like this:
Lines beginning with ":" such as :push, :say are EVENTS.
Lines in between are usually the ESC API functions calls. They are called COMMANDS.

Steps
* compile_script(path/to/esc) : called once
  * compile(path/to/esc, errors) : called once
    * read_events() : called once\
      create an ESCState, initialized with 1st line\
      for each line in ESCState that corresponds to an event (:event), create a new level
      * add_level(state, level, errors)\
        for each state.line that belongs to same group (same indentation), create a command
        * read_cmd(state, level, errors)\
        get the token in state.line : this is the actual command (say, teleport, etc.)\
        get the parameters next to the token\
        create an ESCCommand, check it and push it into level array\
      * create an ESCEvent with the level created\
      * add it to the returned Dictionary of events

In the end, the ESCState has read all lines in the file and is deleted

Returned value is a Dictionary { event name : ESCEvent}

And ESCEvent.level is an array of ESCCommand

## Constants Descriptions

### COMMANDS

```gdscript
const COMMANDS: Dictionary = {"!":{"alias":"end_dialog","min_args":0},"%":{"alias":"label","min_args":1},">":{"alias":"branch"},"?":{"alias":"dialog"},"accept_input":{"min_args":1,"types":[4]},"anim":{"min_args":2,"types":[4,4,1,1,1]},"autosave":{"min_args":0},"camera_push":{"min_args":1,"types":[4]},"camera_set_drag_margin_enabled":{"min_args":2,"types":[1,1]},"camera_set_limits":{"min_args":1,"types":[2]},"camera_set_pos":{"min_args":3,"types":[3,2,2]},"camera_set_target":{"min_args":1,"types":[3]},"camera_set_zoom":{"min_args":1,"types":[3]},"camera_set_zoom_height":{"min_args":1,"types":[2]},"camera_shift":{"min_args":2,"types":[2,2]},"change_scene":{"min_args":1,"types":[4,1]},"custom":{"min_args":2,"types":[4,4]},"cut_scene":{"min_args":2,"types":[4,4,1,1,1]},"debug":{"min_args":1},"dec_global":{"min_args":2,"types":[4,2]},"enable_terrain":{"min_args":1,"types":[4]},"game_over":{"min_args":1,"types":[1]},"inc_global":{"min_args":2,"types":[4,2]},"inventory_add":{"min_args":1},"inventory_display":{"min_args":1,"types":[1]},"inventory_remove":{"min_args":1},"jump":{"min_args":1},"label":{"min_args":1},"queue_animation":{"min_args":2,"types":[4,4,1]},"queue_resource":{"min_args":1,"types":[4,1]},"repeat":true,"say":{"min_args":2},"sched_event":{"min_args":3,"types":[3,4,4]},"set_active":{"min_args":2,"types":[4,1]},"set_angle":{"min_args":2,"types":[4,2]},"set_global":{"min_args":2,"types":[4,4]},"set_globals":{"min_args":2,"types":[4,1]},"set_hud_visible":{"min_args":1,"types":[1]},"set_interactive":{"min_args":2,"types":[4,1]},"set_sound_state":{"min_args":2,"types":[4,4,1]},"set_speed":{"min_args":2,"types":[4,2]},"set_state":{"min_args":2,"types":[4,4,1]},"slide":{"min_args":2},"slide_block":{"min_args":2},"spawn":{"min_args":1},"stop":true,"superpose_scene":{"min_args":1,"types":[4,1]},"teleport":{"min_args":2,"types":[4,4,2]},"teleport_pos":{"min_args":3},"turn_to":{"min_args":2},"wait":true,"walk":{"min_args":2},"walk_block":{"min_args":2},"walk_to_pos":{"min_args":3},"walk_to_pos_block":{"min_args":3}}
```

A list of valid ESC commands

### DEBUG\_COMMANDS

```gdscript
const DEBUG_COMMANDS: Dictionary = {"get_active":{"min_args":1,"types":[4]},"get_global":{"min_args":1,"types":[4]},"get_interactive":{"min_args":1,"types":[4]},"get_state":{"min_args":1,"types":[4]}}
```

Commands that can be called only by the ESC debug prompt

## Method Descriptions

### compile\_str

```gdscript
func compile_str(p_str: String, errors: Array)
```

Compile a string into a dictionary of ESC events

#### Parameters

- p_str: String to compile
- errors: List of errors occured during parsing
**Returns** A dictionary of ESCEvents

### load\_esc\_file

```gdscript
func load_esc_file(esc_file_path: String) -> Dictionary
```

Loads an ESC or special GDScript file and compiles it to a dictionary of
events.

#### Parameters

- esc_file_path: The path to the ESC file to load
**Returns** A dictionary of ESC events

### compile\_script

```gdscript
func compile_script(p_path: String) -> Dictionary
```

Compiles an ESC file into a dictionary of events.
Alternatively, a GDScript file can be specified as well. In that case,
the compiler expects a function get_events in that script that
returns a dictionary of events.

#### Parameters

- p_path: Path to the ESC/GDScript-file
**Returns** A dictionary of ESC events

### compile

```gdscript
func compile(p_fname: String, errors: Array) -> Dictionary
```

Compile an ESC file into a list of events

#### Parameters

- p_fname: Path to the ESC file
- errors: A list of errors that wil be filled by the compiler
**Returns** A dictionary of ESC events

### read\_events

```gdscript
func read_events(f, ret: Dictionary, errors: Array) -> void
```

Parse a file or a special dictionary into a dictionary of ESC events

The dictionary is currently used as a workaround to parse ESC from text
(see read_line for specifics)

#### Parameters

- f: File or Dictionary to read
- ret: The parsed dictionary
- errors: A list of errors that have been found during parsing

### add\_level

```gdscript
func add_level(state: ESCState, level: Array, errors: Array) -> void
```

Add a new level of indent to the current event parsing

#### Parameters

- state: The state we're working on
- level: The existing levels
- errors: A list of errors during parsing

### read\_cmd

```gdscript
func read_cmd(state: ESCState, level: Array, errors: Array) -> void
```

Interpret a line in an esc event level as a command and add it to the
level commands

#### Parameters

- state: The state we're working on
- level: The list of level commands
- errors: A list of errors occured during parsing

### add\_dialog

```gdscript
func add_dialog(state: ESCState, level: Array, errors: Array) -> void
```

Add a dialog into the current level

#### Parameters

- state: State we're working on
- level: Current list of level commands
- errors: List of errors occured during parsing

### read\_dialog\_option

```gdscript
func read_dialog_option(state: ESCState, level: Array, errors: Array) -> void
```

### check\_normal\_command

```gdscript
func check_normal_command(cmd: ESCCommand, state: ESCState, errors: Array) -> bool
```

### check\_debug\_command

```gdscript
func check_debug_command(cmd: ESCCommand, state: ESCState, errors: Array) -> bool
```

### check\_command

```gdscript
func check_command(commands_list: Dictionary, cmd: ESCCommand, state: ESCState, errors: Array) -> bool
```

### read\_line

```gdscript
func read_line(state: ESCState) -> void
```

Advance to the next line in the state

#### Parameters

- state: State we're working on

### is\_comment

```gdscript
func is_comment(line: String) -> bool
```

 Check wether line is a comment (starting with #)

#### Parameters

- line: Current line as string
**Returns** Wether the line is a comment or not

### get\_indent

```gdscript
func get_indent(line: String) -> int
```

Returns the position of the first non-blank character in given line string

#### Parameters

- line: Line to check
**Returns** Indent of the checked line

### is\_event

```gdscript
func is_event(line: String)
```

Check wether the given line is a event (begins with ":")

#### Parameters

- line: Line to check
**Returns**

### is\_flags

```gdscript
func is_flags(tk: String) -> bool
```

Checks wetehr the given token is a flag (ie. "[.+]")

#### Parameters

- tk: Token to check
**Returns** Wether the token is a flag or not

### get\_token

```gdscript
func get_token(line: String, p_from: int, line_count: int, errors: Array) -> int
```

### parse\_flags

```gdscript
func parse_flags(p_flags: String, flags_list: Array, ifs: Dictionary)
```

Parses a flags string (usually defined by '[.*]') and fills the flags_list array
and ifs variable (Dictionary containing all ifs conditions)