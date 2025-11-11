## In Godot 4, tweens cannot be resumed. But if you re-create them,[br]
## the bindings are lost. So this class wraps a tween and offers a reset function.
extends RefCounted
class_name Tween3

## Interpolates a property on an object using a tween.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |tween|`Tween`|The Tween instance to use.|yes|[br]
## |object|`Object`|The object whose property will be tweened.|yes|[br]
## |property|`NodePath`|The property to tween.|yes|[br]
## |initial_val|`Variant`|The initial value of the property.|yes|[br]
## |final_val|`Variant`|The final value of the property.|yes|[br]
## |duration|`float`|The duration of the tween in seconds.|yes|[br]
## |trans_type|`Tween.TransitionType`|The transition type (default 0).|no|[br]
## |ease_type|`Tween.EaseType`|The ease type (default 2).|no|[br]
## |delay|`float`|The delay before starting the tween (default 0).|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns True if the interpolation was set up successfully. (`bool`)
static func tween_interpolate_property(
				tween: Tween,
				object: Object, property: NodePath,
				initial_val: Variant, final_val: Variant,
				duration: float,
				trans_type: Tween.TransitionType = 0, ease_type: Tween.EaseType = 2,
				delay: float = 0) -> bool:
	var t := tween.tween_property(object, property, final_val, duration)
	assert(t != null, "Cannot interpolate property \"%s\" in \"%s\"! Did you reset the tween?" % [property, str(object)])

	if initial_val == null:
		t.as_relative()
	else:
		t.from(initial_val)

	t.set_trans(trans_type)
	t.set_ease(ease_type)
	t.set_delay(delay)

	return true


## The parent node for the tween.
var _tween_parent: Node

## The Tween instance being managed.
var _tween: Tween

## The duration of the tween.
var _duration: float

## Emitted when the tween finishes.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
signal finished()

## Called when the tween finishes.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _on_finished():
	finished.emit()

## Constructor.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |tween_parent|`Node`|The parent node for the tween.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _init(tween_parent: Node):
	_tween_parent = tween_parent
	_duration = 0

	_create_tween()

## Creates a new tween instance and connects its finished signal.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func _create_tween():
	_tween = _tween_parent.get_tree().create_tween()
	_tween.pause()  # prevent autoplay

	_tween.finished.connect(_on_finished)

## Resets the tween, stopping and killing the current tween and creating a new one.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func reset():
	_duration = 0
	_tween.stop()
	_tween.kill()

	_create_tween()

## Adds a method tween to the tween sequence.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |method|`Callable`|The method to tween.|yes|[br]
## |from|`Variant`|The initial value.|yes|[br]
## |to|`Variant`|The final value.|yes|[br]
## |duration|`float`|The duration of the tween in seconds.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func tween_method(method: Callable, from: Variant, to: Variant, duration: float) -> void:
	_duration = maxf(_duration, duration)
	_tween.tween_method(method, from, to, duration)

## Interpolates a property on an object using the managed tween.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |object|`Object`|The object whose property will be tweened.|yes|[br]
## |property|`NodePath`|The property to tween.|yes|[br]
## |initial_val|`Variant`|The initial value of the property.|yes|[br]
## |final_val|`Variant`|The final value of the property.|yes|[br]
## |duration|`float`|The duration of the tween in seconds.|yes|[br]
## |trans_type|`Tween.TransitionType`|The transition type (default 0).|no|[br]
## |ease_type|`Tween.EaseType`|The ease type (default 2).|no|[br]
## |delay|`float`|The delay before starting the tween (default 0).|no|[br]
## [br]
## #### Returns[br]
## [br]
## Returns True if the interpolation was set up successfully. (`bool`)
func interpolate_property(
				object: Object, property: NodePath,
				initial_val: Variant, final_val: Variant,
				duration: float,
				trans_type: Tween.TransitionType = 0, ease_type: Tween.EaseType = 2,
				delay: float = 0) -> bool:
	_duration = maxf(_duration, duration)
	return tween_interpolate_property(_tween, object, property, initial_val, final_val, duration, trans_type, ease_type, delay)

## Plays the tween.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func play():
	_tween.play()

## Resumes the tween if it is valid.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func resume():
	if _tween.is_valid():
		_tween.play()

## Pauses the tween.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func pause():
	_tween.pause()

## Stops the tween.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func stop():
	_tween.stop()

## True if the tween is running.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns true if the tween is running. True if the tween is running. (`bool`)
func is_running():
	return _tween.is_running()

## True if the tween is valid.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns true if the tween is valid. True if the tween is valid. (`bool`)
func is_valid():
	return _tween.is_valid()

## Gets the total elapsed time of the tween.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the total elapsed time in seconds. (`Variant`)
func get_total_elapsed_time():
	return _tween.get_total_elapsed_time()

## Gets the duration of the tween.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns the duration of the tween in seconds. (`Variant`)
func get_duration():
	return _duration
