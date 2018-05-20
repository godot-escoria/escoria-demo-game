
const DATA_STRING = 0
const DATA_STRING_ARRAY = 1
const DATA_VARIANT = 2

var base = "user://esc_saves"
var slots = {}
var max_slots = 3
var settings

func save_settings(p_data, p_callback):
	var f = File.new()
	f.open("user://settings.bin", File.WRITE)
	f.store_var(p_data)
	f.close()

	if typeof(p_callback) != typeof(null):
		p_callback[0].call_deferred(p_callback[1], OK)

	return OK

func load_settings(p_callback):
	var f = File.new()
	f.open("user://settings.bin", File.READ)
	if !f.is_open():
		if typeof(p_callback) != typeof(null):
			p_callback[0].call_deferred(p_callback[1], null)
		return FAILED

	settings = f.get_var()
	f.close()

	if typeof(p_callback) != typeof(null):
		p_callback[0].call_deferred(p_callback[1], settings)

	return OK

func _get_fname(p_slot):

	var date = OS.get_date()
	var time = OS.get_time()

	var day = str(date.day)
	if date.day < 10:
		day = "0"+day


	var hour = str(time.hour)
	if time.hour < 10:
		hour = "0"+hour

	var minute = str(time.minute)
	if time.minute < 10:
		minute = "0"+minute

	var second = str(time.second)
	if time.second < 10:
		second = "0"+second

	var fname = str(p_slot) + "-"
	fname = fname + day + "-" + str(date.month) + "-" + str(date.year) + " " + hour+"."+minute+"."+second+".esc"

	return fname


func save_game(p_data, p_slot, p_callback):

	if p_slot < 0 || p_slot >= max_slots:
		return FAILED

	var fname = _get_fname(p_slot)
	var ret = _do_save(base + "/" + fname, p_data)
	if ret != OK:
		if typeof(p_callback) != typeof(null):
			p_callback[0].call_deferred(p_callback[1], FAILED)
		return FAILED

	if p_slot in slots:
		var old_fname = slots[p_slot].fname
		var d = Directory.new()
		d.open(base)
		d.remove(old_fname)

	if typeof(p_callback) != typeof(null):
		p_callback[0].call_deferred(p_callback[1], OK)
	return OK

func _do_save(fname, p_data):
	var f = File.new()
	var ret = f.open(fname, File.WRITE)
	if !f.is_open():
		print("Unable to open file for save ", fname)
		return FAILED

	if typeof(p_data) == typeof([]):
		for s in p_data:
			f.store_string(s)
	else:
		f.store_string(p_data)

	f.close()

	return OK

func load_slot(p_slot, p_callback):
	if p_callback == null:
		return FAILED

	if !(p_slot in slots):
		return FAILED

	var data = _do_load(slots[p_slot].fname)
	if !data:
		return FAILED

	p_callback[0].call_deferred(p_callback[1], data)

	return OK

func load_autosave(p_callback):
	if p_callback == null:
		return FAILED

	var data = _do_load("user://quick_save.esc")
	if data == null:
		return FAILED

	p_callback[0].call_deferred(p_callback[1], data)

	return OK


func _do_load(fname):

	var f = File.new()
	if !f.file_exists(fname):
		return null

	f.open(fname, File.READ)
	var data = f.get_as_text()
	f.close()

	return data


func autosave(p_data, p_callback):
	var err = _do_save("user://quick_save.esc", p_data)

	if typeof(p_callback) != typeof(null):
		p_callback[0].call_deferred(p_callback[1], err)

	return err

func get_slots_available(p_callback):

	if p_callback == null:
		return FAILED

	var d = Directory.new()
	d.open("user://")
	if !d.dir_exists(base):
		d.make_dir(base)
	d.open(base)


	d.list_dir_begin()
	var f = d.get_next()
	while f != "":

		if f.find(".esc") < 0 || f.find("-") < 0:
			f = d.get_next()
			continue

		var sep = f.find("-")
		var n = int(f.substr(0, sep))
		if n >= max_slots:
			f = d.get_next()
			continue

		var t = f.replace(".esc", "")
		t = t.substr(2, t.length()-2)
		var l = t.split(" ")
		var h = l[1]
		var date = l[0]

		slots[n] = { "n": n, "fname": base + "/" + f, "date": date, "hour": h }

		f = d.get_next()

	d.list_dir_end()

	p_callback[0].call_deferred(p_callback[1], slots)

	return OK

func autosave_available():
	var f = File.new()
	return f.file_exists("user://quick_save.esc")

# FIXME: Having this here halts the web build
#func start():
#	pass
