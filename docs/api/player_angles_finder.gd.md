<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# player\_angles\_finder.gd

**Extends:** [Node2D](../Node2D)

## Description

## Enumerations

### Directions

```gdscript
const Directions: Dictionary = {"EAST":2,"NORTH":0,"NORTHEAST":1,"NORTHWEST":7,"SOUTH":4,"SOUTHEAST":3,"SOUTHWEST":5,"WEST":6}
```

## Constants Descriptions

### POLYGON\_DISTANCE

```gdscript
const POLYGON_DISTANCE: int = 400
```

### starting\_angles

```gdscript
const starting_angles: Array = [0,0.785398,1.570796,2.356194,3.141593,3.926991,4.712389,5.497787]
```

## Property Descriptions

### number\_of\_directions

```gdscript
var number_of_directions: int
```

### angle\_horizontal\_axes

```gdscript
var angle_horizontal_axes: float
```

### angle\_vertical\_axes

```gdscript
var angle_vertical_axes: float
```

### angle\_diagonal\_axes

```gdscript
var angle_diagonal_axes: float
```

### colors

```gdscript
var colors
```

### result\_angles

```gdscript
var result_angles
```

## Method Descriptions

### clear\_areas\_node

```gdscript
func clear_areas_node()
```

### calculate\_areas

```gdscript
func calculate_areas(nb_directions: int = 8)
```

### construct\_scene\_nodes

```gdscript
func construct_scene_nodes(angles)
```

### clamp360

```gdscript
func clamp360(angle: float)
```

