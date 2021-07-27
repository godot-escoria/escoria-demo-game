<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# CameraSetLimitsCommand

**Extends:** [ESCBaseCommand](../ESCBaseCommand) < [Node](../Node)

## Description

`camera_set_limits camlimits_id`

Sets the camera limits to the one defined under `camlimits_id` in ESCRoom's
camera_limits array.
- camlimits_id: int: id of the camera limits to apply (defined in ESCRoom's
  camera_limits array)

@ESC

## Method Descriptions

### configure

```gdscript
func configure() -> ESCCommandArgumentDescriptor
```

Return the descriptor of the arguments of this command

### validate

```gdscript
func validate(arguments: Array)
```

Validate wether the given arguments match the command descriptor

### run

```gdscript
func run(command_params: Array) -> int
```

Run the command