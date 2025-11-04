## `change_scene(path: String[, enable_automatic_transition: Boolean[, run_events: Boolean]])`
##
## Switches the game from the current scene to another scene. Use this to move the player to a new room when they walk through an unlocked door, for example.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |path|`String`|Path of the new scene|yes|[br]
## |enable_automatic_transition|`Boolean`|Automatically transition to the new scene (default: `true`)|no|[br]
## |run_events|`Boolean`|Run the standard ESC events of the new scene (default: `true`)|no|[br]
## [br]
## @ESC
## @COMMAND
extends ESCBaseCommand
class_name ChangeSceneCommand


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
		[TYPE_STRING, TYPE_BOOL, TYPE_BOOL],
		[null, true, true]
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
		"[%s] Changing scene to %s (enable_automatic_transition = %s)."
				% [
					get_command_name(),
					command_params[0],	# scene file
					command_params[1]	# enable_automatic_transition
				]
	)

	escoria.room_manager.change_scene_to_file(command_params[0], command_params[1])

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
