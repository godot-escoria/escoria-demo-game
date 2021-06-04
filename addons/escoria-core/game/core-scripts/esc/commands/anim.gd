# `anim object name [reverse]`
#
# Executes the animation specificed with the "name" parameter on the object, 
# without blocking. The next command in the event will be executed immediately 
# after. Optional parameters:
#
# * reverse: plays the animation in reverse when true
#
# @ESC
extends ESCBaseCommand
class_name AnimCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING, TYPE_BOOL],
		[null, null, false]
	)
	
	
# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"anim: invalid object",
			[
				"Object with global id %s not found." % arguments[0]
			]
		)
		return false
	return .validate(arguments)


# Run the command
func run(command_params: Array) -> int:
	var obj = escoria.object_manager.objects[command_params[0]]
	var anim_id = command_params[1]
	var reverse = command_params[2]
	var animator = (obj.node as ESCItem).get_animation_player()
	if reverse:
		animator.play_backwards(anim_id)
	else:
		animator.play(anim_id)
	return ESCExecution.RC_OK
