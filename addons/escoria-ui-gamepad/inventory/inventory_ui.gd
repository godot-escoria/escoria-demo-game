extends ESCInventory


# Whether the inventory is visible currently
var inventory_visible: bool = false

var hovering_inventory_item: bool = false

var _tween: Tween3

var being_closed: bool
var being_opened: bool

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
	if being_opened:
		return
	being_opened = true
	_tween.stop()
	_tween.reset()
	var start_pos_y = inventory_scene.position.y
	var end_pos_y = get_viewport_rect().size.y - inventory_scene.size.y
	_tween.interpolate_property(
		inventory_scene,
		"position:y",
		start_pos_y,
		end_pos_y,
		0.4,
		Tween.TransitionType.TRANS_CUBIC
	)
	_tween.play()
	await _tween.finished
	_tween.stop()
	inventory_visible = true
	being_opened = false

func hide_inventory():
	if being_closed:
		return
	being_closed = true
	_tween.stop()
	_tween.reset()
	var start_pos_y = inventory_scene.position.y
	var end_pos_y = get_viewport_rect().size.y - _inventory_title_height
	_tween.interpolate_property(
		inventory_scene,
		"position:y",
		start_pos_y,
		end_pos_y,
		0.4,
		Tween.TransitionType.TRANS_CUBIC
	)
	_tween.play()
	await _tween.finished
	_tween.stop()
	inventory_visible = false
	being_closed = false


func detector_in():
	if not inventory_visible:
		inventory_scene.get_node("MarginContainer/ScrollContainer/container").item_focused = false
		show_inventory()


func detector_out():
	if inventory_visible:
		hide_inventory()


func _on_detector_out_gui_input(event):
	detector_out()
