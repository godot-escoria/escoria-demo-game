var vm

var sounds = []
var bg_path = ""
var bg_volume = 1

func get_free_player():
	var player
	for s in sounds:
		if !s.is_playing() && !s.has_meta("action"):
			return s
	var s = StreamPlayer.new()
	add_child(s)
	sounds.push_back(s)
	return s

func is_playing(path):
	for s in sounds:
		if s.is_playing() && s.has_meta("path") && s.get_meta("path") == path:
			return true

	return false

func play_sound(path, volume, balance, loop, slot, p_multiple = false):
	if !p_multiple && is_playing(path):
		return
	var player = get_free_player()
	if path != null && path != "":
		var stream = ResourceLoader.load(path, "", p_multiple)
		if stream == null:
			return
		player.set_stream(null)
		player.set_stream(stream)
	if slot != null:
		player.set_meta("action", ["callback", slot, "sound_finished", path])
	player.set_loop(loop)
	player.set_volume(volume)
	player.play()
	player.set_meta("path", path)
	return player

func pause_all():
	for s in sounds:
		if s.is_playing():
			s.set_paused(true)

func unpause_all():
	for s in sounds:
		if s.is_paused():
			s.set_paused(false)

func bg_music_set_paused(paused):
	get_node("bg").set_paused(paused)

func stop_sound(player):
	if !(player in sounds):
		printt("trying to stop an unknown sound!")
		return
	player.stop()
	player.set_meta("action", null)

func stop_sound_path(p_path):
	var player = null
	for s in sounds:
		if s.has_meta("path") && s.get_meta("path") == p_path:
			player = s
			break

	if player:
		stop_sound(player)


func clear():
	set_bg_music("", 1, 0)
	pass

func _process(time):
	check_sounds()

func check_sounds():
	for s in sounds:
		if s.is_playing():
			continue
		if s.has_meta("action"):
			vm.run_pending_action(s.get_meta("action"))
			s.set_meta("action", null)

	clear_sounds(false)

func clear_sounds(p_force = false):
	var i = sounds.size()
	while i > 0:
		i -= 1
		if p_force || !sounds[i].is_playing():
			sounds[i].queue_free()
			sounds.remove(i)

func scene_changed():
	for s in sounds:
		s.stop()
		if s.has_meta("action"):
			vm.run_pending_action(s.get_meta("action"))
			s.set_meta("action", null)
	clear_sounds(true)

func set_bg_music(path, volume, balance):
	printt("*** sound set bg music", path, bg_path, volume, volume * vm.music_volume)
	if path == null || path == "":
		bg_path = ""
		get_node("bg").set_stream(null)
		return

	bg_volume = volume

	if bg_path != path:
		bg_path = path
		var stream = ResourceLoader.load(path)
		printt("loaded stream ", stream)
		get_node("bg").set_stream(stream)
		get_node("bg").play()

	get_node("bg").set_volume(bg_volume * vm.music_volume)
	get_node("bg").set_loop(true)

	if get_node("bg").is_playing():
		printt("bg is playing")
		get_node("bg").set_paused(false)
	else:
		printt("bg is not playing")
		get_node("bg").play()

func bg_music_volume_changed():
	get_node("bg").set_volume(bg_volume * vm.music_volume)

func _ready():
	vm = get_node("/root/vm")
	vm.connect("music_volume_changed", self, "bg_music_volume_changed")
	#set_process(true)
	vm.connect("scene_changed", self, "scene_changed")
	get_node("timer").connect("timeout", self, "check_sounds")
