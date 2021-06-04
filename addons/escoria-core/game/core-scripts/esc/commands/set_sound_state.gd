# `set_sound_state player sound loop`
#
# Change the sound playing on `player` to `sound` with optional looping if 
# `loop` is true.
# Valid players are "bg_music" and "bg_sound".
# Aside from paths to sound or music files, the values *off* and *default*.
# *default* is the default value.
# are also valid for `sound`
#
# @ESC
extends ESCBaseCommand
class_name SetSoundStateCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		1, 
		[TYPE_STRING, TYPE_STRING, TYPE_BOOL],
		[null, "default", false]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not arguments[0] in ["bg_music", "bg_sound"]:
		escoria.logger.report_errors(
			"SetSoundStateCommand.validate: invalid player",
			[
				"Player %s is invalid found" % arguments[0]
			]
		)
		return false
	if not arguments[1] in ["default", "off"] \
			or not ResourceLoader.exists(arguments[1]):
		escoria.logger.report_errors(
			"SetSoundStateCommand.validate: invalid sound",
			[
				"Sound %s is invalid or not found" % arguments[1]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	escoria.main.get_node(command_params[0])\
			.set_state(command_params[1], command_params[2])
	return ESCExecution.RC_OK
