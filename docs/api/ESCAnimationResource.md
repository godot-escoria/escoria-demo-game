<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCAnimationResource

**Extends:** [Resource](../Resource)

## Description

Resource containing all defined animations and angles for
characters movement.

## Property Descriptions

### dir\_angles

```gdscript
export var dir_angles = []
```

Array containing the different angles available for animations.
Each angle is defined by an array [start_angle, angle_size].
start_angle must be between 0 and 360.
Angle 0 and 360 are the same and correspond to UP/NORTH
90 is RIGHT/EAST, 180 is DOWN/SOUTH, etc

### directions

```gdscript
export var directions = []
```

Array of animations for each direction, from UP to RIGHT_UP clockwise
[animation_name, scale]: scale parameter can be set to -1 to mirror
the animation

### idles

```gdscript
export var idles = []
```

Array containing the idle animations for each direction (in the
order defined by dir_angles): scale parameter can be set to -1 to mirror
the animation

### speaks

```gdscript
export var speaks = []
```

Array containing the speak animations for each direction (in the
order defined by dir_angles): scale parameter can be set to -1 to mirror
the animation