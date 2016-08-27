tool

extends EditorScript

func _find_placeholders(scene, p_anim = null):

	if p_anim == null:
		_find_placeholders(scene, "animation")
		_find_placeholders(scene, "states")
		return

	var anim = scene.get_node(p_anim)
	if anim == null:
		return

	var list = anim.get_animation_list()
	for a in list:
		var res = anim.get_animation(a)
		var count = res.get_track_count()
		for i in range(count):
			var tpath = res.track_get_path(i)
			var npath = str(tpath).split(":")[0]
			var node = scene.get_node(npath)
			if node != null && ((node extends InstancePlaceholder) || node.get_scene_instance_load_placeholder()):
				if !(a in scene.placeholders):
					scene.placeholders[a] = []
				if npath in scene.placeholders[a]:
					continue
				printt("******* adding placeholder ", a, npath, scene.placeholders[a])
				scene.placeholders[a].push_back(npath)


func _run():
	var scene = get_scene()

	scene.placeholders = {}

	_find_placeholders(scene)
