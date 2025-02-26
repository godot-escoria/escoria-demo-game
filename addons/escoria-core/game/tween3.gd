"""
In Godot 4, tweens cannot be resumed. But if you re-create them, the bindings are lost. So this class wraps a tween and offers a reset function.
"""
extends RefCounted
class_name Tween3

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


var _tween_parent: Node
var _tween: Tween
var _duration: float

signal finished()

func _on_finished():
	finished.emit()

func _init(tween_parent: Node):
	_tween_parent = tween_parent
	_duration = 0

	_create_tween()

func _create_tween():
	_tween = _tween_parent.get_tree().create_tween()
	_tween.pause()  # prevent autoplay

	_tween.finished.connect(_on_finished)

func reset():
	_duration = 0
	_tween.stop()
	_tween.kill()

	_create_tween()

func tween_method(method: Callable, from: Variant, to: Variant, duration: float) -> void:
	_duration = maxf(_duration, duration)
	_tween.tween_method(method, from, to, duration)

func interpolate_property(
				object: Object, property: NodePath,
				initial_val: Variant, final_val: Variant,
				duration: float,
				trans_type: Tween.TransitionType = 0, ease_type: Tween.EaseType = 2,
				delay: float = 0) -> bool:
	_duration = maxf(_duration, duration)
	return tween_interpolate_property(_tween, object, property, initial_val, final_val, duration, trans_type, ease_type, delay)

func play():
	#assert(_duration > 0)
	_tween.play()

func resume():
	if _tween.is_valid():
		_tween.play()

func pause():
	_tween.pause()

func stop():
	_tween.stop()

func is_running():
	return _tween.is_running()

func is_valid():
	return _tween.is_valid()

func get_total_elapsed_time():
	return _tween.get_total_elapsed_time()

func get_duration():
	return _duration
