# `set_animations object animations`
#
# Sets the animation resource for the given `ESCPlayer` or movable `ESCItem`.
#
# **Parameters**
#
# - *object*: Global ID of the object whose animation resource is to be updated
# - *animations*: The path of the animation resource to use
#
# @ESC
extends ESCBaseCommand
class_name SetAnimationsCommand


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING],
		[null, null]
	)


# Validate whether the given arguments match the command descriptor
func validate(arguments: Array):
	if not .validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		escoria.logger.error(
			self,
			"[%s]: invalid object. Object with global id %s not found."
					% [get_command_name(), arguments[0]]
		)
		return false
	if not ResourceLoader.exists(arguments[1]):
		escoria.logger.error(
			self,
			"[%s]: invalid animation resource. The animation resource %s was not found."
					% [get_command_name(), arguments[1]]
		)
		return false

	(escoria.object_manager.get_object(arguments[0]).node as ESCPlayer).validate_animations(load(arguments[1]))

	return true


# Run the command
func run(command_params: Array) -> int:
	(escoria.object_manager.get_object(command_params[0]).node as ESCPlayer)\
			.animations = load(command_params[1])
	if not escoria.globals_manager.has(
		escoria.room_manager.GLOBAL_ANIMATION_RESOURCES
	):
		escoria.globals_manager.set_global(
			escoria.room_manager.GLOBAL_ANIMATION_RESOURCES,
			{},
			true
		)
	var animations = escoria.globals_manager.get_global(
		escoria.room_manager.GLOBAL_ANIMATION_RESOURCES
	)
	animations[command_params[0]] = command_params[1]
	escoria.globals_manager.set_global(
		escoria.room_manager.GLOBAL_ANIMATION_RESOURCES,
		animations,
		true
	)
	return ESCExecution.RC_OK


# Function called when the command is interrupted.
func interrupt():
	# Do nothing
	pass

