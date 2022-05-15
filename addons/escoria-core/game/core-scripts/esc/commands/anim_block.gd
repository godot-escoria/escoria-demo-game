# `anim_block object name [reverse]`
#
# Executes the animation specified in "name" on "object" while blocking other
# events from starting.
# The next command in the event will be executed when the animation is
# finished playing.
#
# **Parameters**
#
# * *object*: Global ID of the object with the animation
# * *name*: Name of the animation to play
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


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.error(
			self,
			get_command_name() + ": Object with global id %s not found." 
				% arguments[0]
		)
		return false
	return true


# Run the command
func run(command_params: Array) -> int:
	var obj = escoria.object_manager.get_object(command_params[0])
	var anim_id = command_params[1]
	var reverse = command_params[2]
	var animator: ESCAnimationPlayer = \
			(obj.node as ESCItem).get_animation_player()
	if reverse:
		animator.play_backwards(anim_id)
	else:
		animator.play(anim_id)
	if animator.get_length(anim_id) < 1.0:
		return ESCExecution.RC_OK
	var animation_finished = yield(animator, "animation_finished")
	while animation_finished != anim_id:
		animation_finished = yield(animator, "animation_finished")
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	escoria.logger.warn(
		self,
		"[%s] Interrupt() function not implemented." % get_command_name()
	)
