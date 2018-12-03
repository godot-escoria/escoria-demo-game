extends Node2D

# Custom functions to be used in your game.

# Spine example
func spine_change_skin(params):
	# Show-and-tell, ignore
	var obj = params[0]
	var func_name = params[1]

	# Change all parent's Spine nodes' skins
	var skin = params[2]

	for node in get_parent().get_children():
		if node.get_class() == "Spine":
			node.set_indexed("playback/skin", skin)

