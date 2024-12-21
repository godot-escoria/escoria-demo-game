extends Object
class_name ESCBreakCounter


var _levels_left: int = 0:
	set = set_levels_left, 
	get = get_levels_left


func set_levels_left(levels: int) -> void:
	_levels_left = levels


func get_levels_left() -> int:
	return _levels_left


func dec_levels_left() -> void:
	_levels_left = _levels_left - 1
