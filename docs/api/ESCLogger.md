<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCLogger

**Extends:** [Object](../Object)

## Description

Logging framework for Escoria

## Constants Descriptions

### LOG\_DEBUG

```gdscript
const LOG_DEBUG: int = 3
```

Valid log levels

### LOG\_ERROR

```gdscript
const LOG_DEBUG: int = 3
```

Valid log levels

### LOG\_INFO

```gdscript
const LOG_DEBUG: int = 3
```

Valid log levels

### LOG\_WARNING

```gdscript
const LOG_DEBUG: int = 3
```

Valid log levels

## Property Descriptions

### warning\_path

```gdscript
var warning_path: String
```

The path of the ESC file that was reported last (used for removing
duplicate warnings

## Method Descriptions

### debug

```gdscript
func debug(string: String, args)
```

Log a debug message

#### Parameters

* string: Text to log
* args: Additional information

### info

```gdscript
func info(string: String, args)
```

Log an info message

#### Parameters

* string: Text to log
* args: Additional information

### warning

```gdscript
func warning(string: String, args)
```

Log a warning message

#### Parameters

* string: Text to log
* args: Additional information

### error

```gdscript
func error(string: String, args)
```

Log an error message

#### Parameters

* string: Text to log
* args: Additional information

### report\_warnings

```gdscript
func report_warnings(p_path: String, warnings: Array, report_once = false) -> void
```

Log a warning message about an ESC file

#### Parameters

* p_path: Path to the file
* warnings: Array of warnings to put out
* report_once: Additional messages about the same file will be ignored

### report\_errors

```gdscript
func report_errors(p_path: String, errors: Array) -> void
```

Log an error message about an ESC file

#### Parameters

* p_path: Path to the file
* errors: Array of errors to put out