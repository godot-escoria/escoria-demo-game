# anim_by_angle_block player animation
#
# Plays the selected angled animation specified in "animation" on "player" while 
# blocking other events from starting
# The next command in the event will be executed when the animation is
# finished playing.
#
# Allows you to play custom animations based on the player angle
# similarly to how speak & walking animations are handled.
#
# To add a angled anim, under your ESC Item,
# under Angled Anims, add a new array of ESCAngledAnimationResource objects.
# Each AngledAnimationResource has a *name* and an array of *animationNames*
# e.g. anim_by_angle_block player pickupLow
# -> Plays an angled animation on player called pickupLow that corresponds
# to the current direction of the player
#
# **Parameters**
#
# *player*: Global ID of the `ESCPlayer` or `ESCItem` object that is active
# *animation*: The name of the animation under Angled Animations to be played. 
#
# @ESC
extends ESCBaseCommand
class_name AnimByAngleCommand

func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING],
		[null, null],
		[true, true]
	)

# Validate whether the given args match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.error(
			self,
			"[%s]: Invalid object: Object with global id %s not found."
					% [get_command_name(), arguments[0]]
		)
		return false

	return true

func run(command_params: Array) -> int:
	var anim_id = command_params[1]

	var anim_object_node = (escoria.object_manager.get_object(
		command_params[0]).node as ESCItem
	)

	anim_object_node.anim_by_angle_block(anim_id)
	return ESCExecution.RC_OK