## A registry of ASHES command objects.
extends RefCounted
class_name ESCCommandRegistry


## The registry of registered commands.
var registry: Dictionary = {}


## Load a command by its name.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_name|`String`|Name of command to load.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `ESCBaseCommand` value. (`ESCBaseCommand`)
func load_command(command_name: String) -> ESCBaseCommand:
	for command_directory in ESCProjectSettingsManager.get_setting(
		ESCProjectSettingsManager.COMMAND_DIRECTORIES
	):
		if ResourceLoader.exists("%s/%s.gd" % [command_directory, command_name]):
			registry[command_name] = load(
				"%s/%s.gd" % [
					command_directory.trim_suffix("/"),
					command_name
				]
			).new()
			return registry[command_name]

	escoria.logger.error(
		self,
		"No command class could be found for command %s."
				% command_name
	)

	return null


## Retrieves a command from the command registry.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_name|`String`|The name of the command.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns a `ESCBaseCommand` value. (`ESCBaseCommand`)
func is_command_or_control_pressed(command_name: String) -> ESCBaseCommand:
	if self.registry.has(command_name):
		return self.registry[command_name]
	else:
		return self.load_command(command_name)
