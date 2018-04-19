var last_volume = 1

func _set(name, val):
	if name == "stream/volume_db":
		last_volume = db2linear(val)
		set_volume(last_volume * vm.settings.music_volume)
		return true


func global_volume_changed():
	set_volume(last_volume * vm.settings.music_volume)

func paused(p_paused):
	set_paused(!can_process())


func setup():
	vm = get_node("/root/vm")
	vm.connect("music_volume_changed", self, "global_volume_changed")
	vm.connect("paused", self, "paused")
	add_to_group("music")
	last_volume = get_volume()
	if vm.settings != null:
		set_volume(vm.settings.music_volume * get_volume())

	paused(get_tree().is_paused())

func _ready():
	printt("music player ready, ", get_path(), get_volume_db(), get_volume())
	call_deferred("setup")
