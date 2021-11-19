# `anim_block object name [reverse]`
#
# Executes the animation specificed with the "name" parameter on the object, 
# blocking. The next command in the event will be executed when the animation 
# is finished playing.
#
# **Parameters**
#
# * *object*: Global ID of the object with the animation
# * *name*: Name of the animation
# * *reverse*: Plays the animation in reverse when true
# 
# @ESC
extends ESCBaseCommand
class_name AnimBlockCommand


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
			"anim_block.gd:validate",
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
	var animator: ESCAnimationPlayer = \
			(obj.node as ESCItem).get_animation_player()
	if reverse:
		animator.play_backwards(anim_id)
	else:
		animator.play(anim_id)
	var animation_finished = yield(animator, "animation_finished")
	while animation_finished != anim_id:
		animation_finished = yield(animator, "animation_finished")
	return ESCExecution.RC_OK
