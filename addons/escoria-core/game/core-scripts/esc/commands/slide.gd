# `slide object1 object2 [speed]`
#
# Moves object1 towards the position of object2, at the speed determined by 
# object1's "speed" property, unless overridden. This command is non-blocking. 
# It does not respect the room's navigation polygons, so you can move items 
# where the player can't walk.
#
# @STUB
# @ESC
extends ESCBaseCommand
class_name SlideCommand


# A hash of tweens currently active for animated items
var _tweens: Dictionary


# Return the descriptor of the arguments of this command
func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2, 
		[TYPE_STRING, TYPE_STRING, TYPE_INT],
		[null, null, -1]
	)


# Validate wether the given arguments match the command descriptor
func validate(arguments: Array):
	if not escoria.object_manager.objects.has(arguments[0]):
		escoria.logger.report_errors(
			"slide: invalid first object",
			[
				"Object with global id %s not found" % arguments[0]
			]
		)
		return false	
	if not escoria.object_manager.objects.has(arguments[1]):
		escoria.logger.report_errors(
			"slide: invalid second object",
			[
				"Object with global id %s not found" % arguments[1]
			]
		)
		return false
	return .validate(arguments)


# Slide the object by generating a tween
#
# #### Parameters
#
# - source: The item to slide
# - destination: The destination item to slide to
# - speed: The speed at which to slide (will default to the 
#
# **Returns** The generated (and started) tween
func _slide_object(
	source: ESCObject, 
	destination: ESCObject, 
	speed: int = -1
) -> Tween:
	if speed == -1:
		speed = source.node.speed
		
	if _tweens.has(source.global_id):
		var tween = (_tweens.get(source.global_id) as Tween)
		tween.stop_all()
		if (escoria.main as Node).has_node(tween.name):
			(escoria.main as Node).remove_child(tween)
	
	var tween = Tween.new()
	(escoria.main as Node).add_child(tween)
	
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
	
	tween.start()
	
	_tweens[source.global_id] = tween
	
	return tween
	


# Run the command
func run(command_params: Array) -> int:
	_slide_object(
		escoria.object_manager.get_object(command_params[0]),
		escoria.object_manager.get_object(command_params[1]),
		command_params[2]
	)
	return ESCExecution.RC_OK
