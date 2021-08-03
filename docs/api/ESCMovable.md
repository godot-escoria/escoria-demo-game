<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCMovable

**Extends:** [Node](../Node)

## Description

Node that performs the moving (walk, teleport, terrain scaling...) actions on
its parent node.

## Enumerations

### MovableTask

```gdscript
const MovableTask: Dictionary = {"NONE":0,"SLIDE":2,"WALK":1}
```

Tasks carried out by this walkable node
NONE - The node is inactive
WALK - The node walks the parent somewhere
SLIDE - The node slides the parent somewhere

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
var walk_context: ESCWalkContext
```

The walk context currently carried out by this movable node

### moved

```gdscript
var moved: bool
```

Wether the character was moved at all

### last\_deg

```gdscript
var last_deg: int
```

Angle degrees from the last position to the next

### last\_dir

```gdscript
var last_dir: int
```

Player Direction used to reflect the movement to the new position

### last\_scale

```gdscript
var last_scale: Vector2
```

The last scaling applied to the parent

### pose\_scale

```gdscript
var pose_scale: int
```

Wether the current direction animation is flipped

### parent

```gdscript
var parent
```

Shortcut variable that references the node's parent

### task

```gdscript
var task
```

Currenly running task

## Method Descriptions

### teleport

```gdscript
func teleport(target: Node) -> void
```

Teleports this item to the target position.

#### Parameters

- target: Position2d or ESCItem to teleport to

### teleport\_to

```gdscript
func teleport_to(target: Vector2) -> void
```

Teleports this item to the target position.

#### Parameters

- target: Vector2 target position to teleport to

### walk\_to

```gdscript
func walk_to(pos: Vector2, p_walk_context: ESCWalkContext = null) -> void
```

Walk to a given position

#### Parameters

- pos: Position to walk to
- p_walk_context: Walk context to use

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
func is_angle_in_interval(angle: float, direction_angle: ESCDirectionAngle) -> bool
```

Returns true if given angle is inside the interval given by a starting_angle
and the size.

#### Parameters

- angle: Angle to test
- direction_angle: ESCDirectionAngle resource, containing the starting angle,
 and the size of interval
eg: angle_start=90, angle_size=40 corresponds to angle between 90° and 130°

### set\_angle

```gdscript
func set_angle(deg: int, immediate = true) -> void
```

Sets character's angle and plays according animation.

#### Parameters

- deg int angle to set the character
- immediate
	If true, direction is switched immediately. Else, successive animations are
	used so that the character turns to target angle.