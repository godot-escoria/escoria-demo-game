extends ESCInventory


# Whether the inventory is visible currently
var inventory_visible: bool = false

var hovering_inventory_item: bool = false

var _tween: Tween3

@onready var inventory_scene = $panel

# Height of the title part of the inventory that stays visible when inventory
# is hidden. To be computed depending on the resolution of the game, hardcoded
# here for demonstration purpose.
const _inventory_title_height: int = 34

func _ready() -> void:
	super._ready()
	_tween = Tween3.new(self)
	# Hide inventory by default
	hide_inventory()


func show_inventory():
	_tween.stop()
	_tween.reset()
	var start_pos_y = inventory_scene.position.y
	var end_pos_y = get_viewport_rect().size.y - $panel.size.y
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
	var end_pos_y = get_viewport_rect().size.y - _inventory_title_height 
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


func _on_exit_inventory_area_mouse_entered():
	if inventory_visible:
		hide_inventory()
