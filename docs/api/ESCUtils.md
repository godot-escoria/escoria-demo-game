<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCUtils

**Extends:** [Object](../Object)

## Description

A set of common utilities

## Method Descriptions

### get\_deg\_from\_rad

```gdscript
func get_deg_from_rad(rad_angle: float)
```

Convert radians to degrees

#### Parameters

- rad_angle: Angle in radians
**Returns** Degrees

### get\_re\_group

```gdscript
func get_re_group(re_match: RegExMatch, group: String) -> String
```

Get the content of a reg exp group by name

#### Parameters

- re_match: The RegExMatch object
- group: The name of the group
**Returns** The value of the named regex group in the match

### get\_typed\_value

```gdscript
func get_typed_value(value: String)
```

Return a string value in the correct infered type

#### Parameters

- value: The original value
**Returns** The typed value according to the type inference

### sanitize\_whitespace

```gdscript
func sanitize_whitespace(value: String) -> String
```

Sanitize use of whitespaces in a string. Removes double whitespaces
and converts tabs into space.

#### Paramters

- value: String to work on
**Returns** the string with sanitized whitespaces