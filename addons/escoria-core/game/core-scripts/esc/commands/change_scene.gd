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
	if not .validate(arguments):
		return false

	if not ResourceLoader.exists(arguments[0]):
		escoria.logger.report_errors(
			"change_scene: Invalid scene",
			["Scene %s was not found" % arguments[0]]
		)
		return false
	if not ResourceLoader.exists(
		escoria.project_settings_manager.get_setting(escoria.project_settings_manager.GAME_SCENE)
	):
		escoria.logger.report_errors(
			"change_scene: Game scene not found",
			[
				"The path set in 'ui/game_scene' was not found: %s" % \
						escoria.project_settings_manager.get_setting(
							escoria.project_settings_manager.GAME_SCENE
						)
			]
		)
		return false

	return true


# Run the command
func run(command_params: Array) -> int:
	escoria.logger.info(
		"Changing scene to %s (enable_automatic_transition = %s)" % [
		command_params[0],	# scene file
		command_params[1]	# enable_automatic_transition
	])

	escoria.room_manager.change_scene(command_params[0], command_params[1])

	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.report_warnings(
		get_command_name(),
		[
			"Interrupt() function not implemented"
		]
	)
