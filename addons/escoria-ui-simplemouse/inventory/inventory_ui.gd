extends ESCInventory


# Whether the inventory is visible currently
var inventory_visible: bool = false

var hovering_inventory_item: bool = false

var _tween: Tween3

@onready var inventory_scene = $panel

func _ready() -> void:
	super._ready()
	_tween = Tween3.new(self)
	# Hide inventory by default
	hide_inventory()


func show_inventory():
	_tween.stop()
	_tween.reset()
	var start_pos_y = inventory_scene.position.y
	var end_pos_y = 706
	_tween.interpolate_property(
		inventory_scene,
		"position:y",
		start_pos_y,
		end_pos_y,
		0.6,
		Tween.TransitionType.TRANS_CUBIC
	)
	_tween.play()
	await _tween.finished
	_tween.stop()
	inventory_visible = true


func hide_inventory():
	_tween.stop()
	_tween.reset()
	var start_pos_y = inventory_scene.position.y
	var end_pos_y = 866
	_tween.interpolate_property(
		inventory_scene,
		"position:y",
		start_pos_y,
		end_pos_y,
		0.6,
		Tween.TransitionType.TRANS_CUBIC
	)
	_tween.play()
	await _tween.finished
	_tween.stop()
	inventory_visible = false


func _on_panel_mouse_entered():
	if not inventory_visible:
		$panel/MarginContainer/ScrollContainer/container.item_focused = false
		show_inventory()

func _on_area_2d_mouse_entered():
	if inventory_visible:
		hide_inventory()
