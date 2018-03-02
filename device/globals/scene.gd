extends "res://globals/scene_base.gd"

export(int) var zoom_height_pixels

func _ready():
	if !zoom_height_pixels:
		zoom_height_pixels = get_viewport().size.y

	vm = get_node("/root/vm")
	vm.set_zoom_height(zoom_height_pixels)
	printt("scene.gd set zoom_height ", zoom_height_pixels)

