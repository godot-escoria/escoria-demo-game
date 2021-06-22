<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCTerrain

**Extends:** [Navigation2D](../Navigation2D)

## Description

A walkable Terrains

## Enumerations

### DebugMode

```gdscript
const DebugMode: Dictionary = {"LIGHTMAP":2,"NONE":0,"SCALES":1}
```

Visualize scales or the lightmap for debugging purposes

## Property Descriptions

### scales

```gdscript
export var scales = "[Object:null]"
```

Scaling texture

### scale\_min

```gdscript
export var scale_min = 0.3
```

Minimum scaling

### scale\_max

```gdscript
export var scale_max = 1
```

Maximum scaling

### lightmap

```gdscript
export var lightmap = "[Object:null]"
```

Lightmap texture

### bitmaps\_scale

```gdscript
export var bitmaps_scale = "(1, 1)"
```

The scaling factor for the scale and light maps

### player\_speed\_multiplier

```gdscript
export var player_speed_multiplier = 1
```

Multiplier applied to the player speed on this terrain

### player\_doubleclick\_speed\_multiplier

```gdscript
export var player_doubleclick_speed_multiplier = 1.5
```

Multiplier how much faster the player will walk when fast mode is on
(double clicked)

### lightmap\_modulate

```gdscript
export var lightmap_modulate = "1,1,1,1"
```

Additional modulator to the lightmap texture

### debug\_mode

```gdscript
export var debug_mode = 0
```

Currently selected debug visualize mode

### current\_active\_navigation\_instance

```gdscript
var current_active_navigation_instance: NavigationPolygonInstance
```

The currently activ navigation polygon

## Method Descriptions

### get\_light

```gdscript
func get_light(pos: Vector2) -> Color
```

Return the Color of the lightmap pixel for the specified position

#### Parameters

- pos: Position to calculate lightmap for
**Returns** The color of the given point

### get\_scale\_range

```gdscript
func get_scale_range(factor: float) -> Vector2
```

Calculate the scale inside the scale range for a given scale factor

#### Parameters

- factor: The factor for the scaling according to the scale map
**Returns** The scaling

### get\_terrain

```gdscript
func get_terrain(pos: Vector2) -> float
```

Get the terrain scale factor for a given position

#### Parameters

- pos: The position to calculate for
**Returns** The scale factor for the given position