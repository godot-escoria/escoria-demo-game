# A registry of ESC command objects
extends Object
class_name ESCCommandRegistry


# The registry of registered commands
var registry: Dictionary = {}


# Load a command by its name
#
# #### Parameters
#
# - command_name: Name of command to load
# **Returns** The command object
func load_command(command_name: String) -> ESCBaseCommand:
	for command_directory in ProjectSettings.get(
		"escoria/main/command_directories"
	):
		if ResourceLoader.exists("%s/%s.gd" % [command_directory, command_name]):
			registry[command_name] = load(
				"%s/%s.gd" % [command_directory, command_name]
			).new()
			return registry[command_name]
	
	escoria.logger.report_errors(
		"ESCCommandRegistry.load_command: Command not found",
		[
			"No command class could be found for command %s" %
				command_name
		]
	)

	return null


# Retrieve a command from the command registry
# 
# #### Parameters
#
# - command_name: The name of the command
# **Returns** The command object
func get_command(command_name: String) -> ESCBaseCommand:
	if self.registry.has(command_name):
		return self.registry[command_name]
	else:
		return self.load_command(command_name)
