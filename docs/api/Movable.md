<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# Movable

**Extends:** [Node](../Node)

## Description

Node that performs the moving (walk, teleport, terrain scaling...) actions on
its parent node.

## Property Descriptions

### walk\_path

```gdscript
var walk_path: Array
```

Character path through the scene as calculated by the Pathfinder

### path\_ofs

```gdscript
var path_ofs: int
```

Current active walk path entry

### walk\_destination

```gdscript
var walk_destination: Vector2
```

The destination where the character should be moving to

### walk\_context

```gdscript
var walk_context: Dictionary
```

A dictionary with context information about the walk command
fast => Wether to walk fast or slow
target => Walk target

### moved

```gdscript
var moved: bool
```

Wether the character was moved at all

### last\_deg

```gdscript
var last_deg: int
```

Angle degrees to the last position (TODO is that correct?)

### last\_dir

```gdscript
var last_dir: int
```

Direction of the last position (TODO is that correct?)

### last\_scale

```gdscript
var last_scale: Vector2
```

Scale of the last position (TODO is that correct?)

### pose\_scale

```gdscript
var pose_scale: int
```

TODO Isn't this actually the flip state of the current animation?

### parent

```gdscript
var parent
```

Shortcut variable that references the node's parent

### bypass\_missing\_animation

```gdscript
var bypass_missing_animation
```

 If character misses an animation, bypass it and proceed.

## Method Descriptions

### teleport

```gdscript
func teleport(target, angle: Object = null) -> void
```

Teleports this item to the target position.
TODO angle is only used for logging and has no further use, so it probably
can be removed

#### Parameters

- target: Vector2, Position2d or ESCItem

### walk\_to

```gdscript
func walk_to(pos: Vector2, p_walk_context = null) -> void
```

Walk to a given position

#### Parameters

- pos: Position to walk to
- p_walk_context: Walk context to use

### walk

```gdscript
func walk(target_pos, p_speed, context = null) -> void
```

FIXME this function doesn't seem to be used anywhere

### walk\_stop

```gdscript
func walk_stop(pos: Vector2) -> var
```

We have finished walking. Set the idle pose and complete

#### Parameters

- pos: Final target position

### update\_terrain

```gdscript
func update_terrain(on_event_finished_name = null) -> void
```

Update the sprite scale and lighting

#### Parameters

- on_event_finished_name: Used if this function is called from an ESC event

### is\_angle\_in\_interval

```gdscript
func is_angle_in_interval(angle: float, interval: Array) -> bool
```

Returns true if given angle is inside the interval given by a starting_angle
and the size.
TODO Refactor to make this stuff understandable :D

#### Parameters

- angle: Angle to test
- interval : Array of size 2, containing the starting angle, and the size of
  interval
  eg: [90, 40] corresponds to angle between 90° and 130°

### set\_angle

```gdscript
func set_angle(deg: int, immediate = true) -> void
```

Sets character's angle and plays according animation.

TODO: depending on current angle and current angle, the character may
directly turn around with no "progression". We may enhance this by
calculating successive directions to turn the character to, so that he
doesn't switch to opposite direction too fast.
For example, if character looks WEST and set_angle(EAST) is called, we may
want the character to first turn SOUTHWEST, then SOUTH, then SOUTHEAST and
finally EAST, all more or less fast.
Whatever the implementation, this should be activated using "parameter
"immediate" set to false.

#### Parameters

- deg int angle to set the character
- immediate bool (currently unused, see TODO below)
	If true, direction is switched immediately. Else, successive animations are
	used so that the character turns to target angle.