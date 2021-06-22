<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCCompiler

**Extends:** [Object](../Object)

## Description

Compiler of the ESC language

## Constants Descriptions

### COMMENT\_REGEX

```gdscript
const COMMENT_REGEX: String = "^\\s*#.*$"
```

A RegEx for comment lines
.*$'

### EMPTY\_REGEX

```gdscript
const EMPTY_REGEX: String = "^\\s*$"
```

A RegEx for empty lines

### INDENT\_REGEX

```gdscript
const INDENT_REGEX: String = "^(?<indent>\\s*)"
```

A RegEx for finding out the indent of a line

## Method Descriptions

### load\_esc\_file

```gdscript
func load_esc_file(path: String) -> ESCScript
```

Load an ESC file from a file resource

### compile

```gdscript
func compile(lines: Array) -> ESCScript
```

Compiles an array of ESC script strings to an ESCScript