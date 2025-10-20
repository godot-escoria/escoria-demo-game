## `slide(object: String, target: String[, speed: Integer])`
##
## Moves `object` towards the position of `target`. This command is
## non-blocking.[br]
##[br]
## - *object*: Global ID of the object to move[br]
## - *target*: Global ID of the target object[br]
## - *speed*: The speed at which to slide in pixels per second (will default to
##   the speed configured on the `object`)[br]
##[br]
## **Warning** This command does not respect the room's navigation polygons, so
## `object` can be moved even when outside walkable areas.
##
## @ESC
extends ESCBaseCommand
class_name SlideCommand


## A hash of tweens currently active for animated items
var _tweens: Dictionary


## Returns the descriptor of the arguments of this command.[br]
## [br]
## *Returns* The argument descriptor for this command.
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[TYPE_STRING, TYPE_STRING, TYPE_INT],
		[null, null, -1]
	)


## Validates whether the given arguments match the command descriptor.[br]
## [br]
## #### Parameters[br]
## [br]
## - arguments: The arguments to validate.[br]
## [br]
## *Returns* True if the arguments are valid, false otherwise.
func validate(arguments: Array):
	if not super.validate(arguments):
		return false

	if not escoria.object_manager.has(arguments[0]):
		raise_error(
			self,
			"Invalid first object. Object with global id '%s' not found." % arguments[0]
		)
		return false
	if not escoria.object_manager.has(arguments[1]):
		raise_error(
			self,
			"Invalid second object. Object with global id '%s' not found." % arguments[1]
		)
		return false
	return true


## Slide the object by generating a tween[br]
## [br]
## #### Parameters[br]
## [br]
## - *source*: The item to slide[br]
## - *destination*: The destination item to slide to[br]
## - *speed*: The speed at which to slide in pixels per second (will default to
##   the speed configured on the `object`)[br]
## [br]
## *Returns* The generated (and started) tween
func _slide_object(
	source: ESCObject,
	destination: ESCObject,
	speed: int = -1
) -> Tween3:
	if speed == -1:
		speed = source.node.speed
	var tween: Tween3
	if _tweens.has(source.global_id):
		tween = (_tweens.get(source.global_id) as Tween3)
		tween.stop_all()
	else:
		tween = Tween3.new(source.node)
		tween.finished.connect(_on_tween_completed)

	var duration = source.node.position.distance_to(
		destination.node.position
	) / speed

	tween.interpolate_property(
		source.node,
		"global_position",
		source.node.global_position,
		destination.node.global_position,
		duration
	)

	tween.play()
	_tweens[source.global_id] = tween
	return tween



## Runs the command.[br]
## [br]
## #### Parameters[br]
## [br]
## - command_params: The parameters for the command.[br]
## [br]
## *Returns* The execution result code.
func run(command_params: Array) -> int:
	_slide_object(
		escoria.object_manager.get_object(command_params[0]),
		escoria.object_manager.get_object(command_params[1]),
		command_params[2]
	)
	return ESCExecution.RC_OK


## Function called when the command is interrupted.
func interrupt():
	for tween in _tweens:
		tween.stop_all()

## Function called when a tween completes.[br]
## [br]
## #### Parameters[br]
## [br]
## - tween: The tween that completed.[br]
## - _key: The key of the tween in the `_tweens` dictionary (not used here).
func _on_tween_completed(tween: Tween, _key: NodePath):
	if tween:
		tween.queue_free()
