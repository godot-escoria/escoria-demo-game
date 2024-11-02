# `change_scene path [enable_automatic_transition] [run_events]`
#
# Switches the game from the current scene to another scene. Use this to move
# the player to a new room when they walk through an unlocked door, for
# example.
#
# **Parameters**
#
# - *path*: Path of the new scene
# - *enable_automatic_transition*: Automatically transition to the new scene
#   (default: `true`)
# - *run_events*: Run the standard ESC events of the new scene (default: `true`)
#
# @ESC
extends ESCBaseCommand
class_name ChangeSceneCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1,
		[TYPE_STRING, TYPE_BOOL, TYPE_BOOL],
		[null, true, true]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array) -> bool:
	if not super.validate(arguments):
		return false

	if not ResourceLoader.exists(arguments[0]):
		escoria.logger.error(
			self,
			"[%s]: Invalid scene. Scene %s was not found."
					% [get_command_name(), arguments[0]]
		)
		return false
	if not ResourceLoader.exists(
		ESCProjectSettingsManager.get_setting(ESCProjectSettingsManager.GAME_SCENE)
	):
		escoria.logger.error(
			self,
			"[%s]: Game scene not found. The path set in 'ui/game_scene' was not found: %s."
					% [
						get_command_name(),
						ESCProjectSettingsManager.get_setting(
							ESCProjectSettingsManager.GAME_SCENE
						)
					]
		)
		return false

	return true


# Run the command
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


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.debug(
		self,
		"[%s] interrupt() function not implemented." % get_command_name()
	)
