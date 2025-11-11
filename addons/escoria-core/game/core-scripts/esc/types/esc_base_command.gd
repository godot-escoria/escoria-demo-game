## Abstract base class for every ESC command.
##
## Extending classes have to override the configure and run function
extends Resource
class_name ESCBaseCommand


## The filename from which the relevant command is being called, if available.
var filename: String = ""

## The line number from the file the relevant command is being called from.
var line_number: int = 0


## A descriptor (contained in `ESCCommandArgumentDescriptor`) of the arguments of this command.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a descriptor (contained in `ESCCommandArgumentDescriptor`) of the arguments of this command. (`ESCCommandArgumentDescriptor`)
func configure() -> ESCCommandArgumentDescriptor:
	escoria.logger.error(
		self,
		"Command %s did not override configure. Please implement a configure() function." % get_command_name()
	)
	return ESCCommandArgumentDescriptor.new()


## Validates whether the given arguments match the command descriptor, returning `true` iff the command's descriptor can successfully validate the arguments. Should be overridden for each command's own needs, with this method called from the child class.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |arguments|`Array`|an array containing the arguments to be passed to the command|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `bool` value. (`bool`)
func validate(arguments: Array) -> bool:
	var argument_descriptor = self.configure()

	argument_descriptor.filename = filename
	argument_descriptor.line_number = line_number

	return argument_descriptor.validate(get_command_name(), arguments)


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_params|`Array`|an array containing the arguments|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `int` value. (`int`)
func run(command_params: Array) -> int:
	raise_error(self, "Command %s did not override run. Please implement a run() function." % get_command_name())

	return 0


## The name of the command based on the script's filename.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the name of the command based on the script's filename. (`String`)
func get_command_name() -> String:
	var path := get_script().get_path() as String

	return path.get_basename().get_file()


## Method to be called when the command is interrupted.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func interrupt():
	escoria.logger.debug(
		self,
		"Command %s did not override interrupt. Please implement an interrupt() function." % get_command_name()
	)


## Sends an error to the Escoria logger.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command|`Variant`|the command object causing the error; must extend `ESCBaseCommand`.|yes|[br]
## |message|`String`|the message the logger should print to describe the error|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func raise_error(command, message: String) -> void:
	escoria.logger.error(
		command,
		"[%s]: %s %s" % [get_command_name(), message, _get_error_info()]
	)


## Raises an error specific to no object being found with `global_id` as its identifier. `command` is the actual command implementation generating the error.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command|`Variant`|the command object causing the error; must extend `ESCBaseCommand`.|yes|[br]
## |global_id|`String`|the `global_id` that could not be found|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func raise_invalid_object_error(command, global_id: String) -> void:
	raise_error(command, "Invalid object. Object with global id %s not found." % global_id)


## A string with the file and line number for error reporting.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a string with the file and line number for error reporting. The error info string. (`String`)
func _get_error_info() -> String:
	return "(File: \"%s\", line %s.)" % [filename, line_number]
