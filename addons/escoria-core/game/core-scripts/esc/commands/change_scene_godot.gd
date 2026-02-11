## `change_scene_godot(path: String)`
##
## Switches the game from the current scene to a Godot scene, without using Escoria.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |path|`String`|Path of the new scene|yes|[br]
## [br]
## @ASHES
## @COMMAND
extends ESCBaseCommand
class_name ChangeSceneGodotCommand


## The descriptor of the arguments of this command.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the descriptor of the arguments of this command. The argument descriptor for this command. (`ESCCommandArgumentDescriptor`)
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING],
		[null]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |arguments|`Array`|The arguments to validate.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns True if the arguments are valid, false otherwise. (`bool`)
func validate(arguments: Array) -> bool:
	if not super.validate(arguments):
		return false

	if not ResourceLoader.exists(arguments[0]):
		raise_invalid_object_error(self, arguments[0])
		return false
	if not ResourceLoader.exists(
		ESCProjectSettingsManager.get_setting(ESCProjectSettingsManager.GAME_SCENE)
	):
		raise_error(self, "Game scene not found. The path set in 'ui/game_scene' was not found: %s."
					% [
						ESCProjectSettingsManager.get_setting(
							ESCProjectSettingsManager.GAME_SCENE
						)
					])

		return false

	return true


## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |command_params|`Array`|The parameters for the command.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns the execution result code. (`int`)
func run(command_params: Array) -> int:
	escoria.logger.info(
		self,
		"[%s] Changing scene to Godot scene %s."
				% [
					get_command_name(),
					command_params[0]	# scene file
				]
	)

	escoria.room_manager.change_scene_to_godot_file(command_params[0])

	return ESCExecution.RC_OK


## Function called when the command is interrupted.[br]
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
		"[%s] interrupt() function not implemented." % get_command_name()
	)
