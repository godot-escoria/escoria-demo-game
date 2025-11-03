## `set_angle(object: String, target_degrees: Number[, wait: Number])`
##
## Turns a movable `ESCItem` or `ESCPlayer` to face a given target direction. Angles 0 and 360 are the same and correspond to UP/NORTH, 90 is RIGHT/EAST, 180 is DOWN/SOUTH, 270 is LEFT/WEST etc. The rotation direction will be determined by the shortest path - e.g. rotating from facing up (0 degrees) to left (270) will be a 90 degree turn anti-clockwise rather than a 270 degree clockwise turn. The final animation used is determined by the directions which have been configured for the object. If the item has a direction configured which has been drawn to show it facing to the right, and this direction has been defined to cover the angle from 45 to 135 degrees, setting the target angle to 120 degrees will result in the right-facing animation being used. The number of intermediate animations shown while turning the item will depend on the directions specified in the item's definition. A 16 direction character will turn through 8 different directions to turn 180 degrees, a 4 direction character only 2. The wait time will determine how long the idle animation for each direction is played before using the next direction's animation. As such, if wait was set to 1 second, a 16 direction character would take 8 seconds to turn 180 degrees, a 4 direction character would take 2 seconds.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object|`String`|Global ID of the object to turn|yes|[br]
## |target_degrees|`Number`|Number of degrees by which `object` is to be turned|yes|[br]
## |wait|`Number`|Number of seconds to wait for while playing each animation occurring between the current angle of `object` and the target angle. A value of `0` will complete the turn immediately (default: `0`)|no|[br]
## [br]
## @ESC
extends ESCBaseCommand
class_name SetAngleCommand


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
		2,
		[TYPE_STRING,  [TYPE_FLOAT, TYPE_INT],  [TYPE_FLOAT, TYPE_INT]],
		[null, null, 0.0]
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
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		raise_invalid_object_error(self, arguments[0])
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
	# HACK Countering the fact that angle_to_point() function gives
	# angle against X axis not Y, we need to check direction using (angle-90°).
	# Since the ESC command already gives the right angle, we add 90.
	escoria.object_manager.get_object(command_params[0]).node\
			.set_angle(
				wrapi(int(command_params[1]) - 90, 0, 360),
				command_params[2]
			)
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
	# Do nothing
	pass
