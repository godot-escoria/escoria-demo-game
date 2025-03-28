## Represents a compiled ASHES script.
extends Resource
class_name ESCScript


## A dictionary of `ESCEvent`s contained in this script.
var events: Dictionary

## The name of the ASHES file parsed for this script, if this script was in fact
## loaded from a file (as opposed to being from an internal string).
var filename: String = ""
