var ICloud = null

const DATA_STRING = 0
const DATA_STRING_ARRAY = 1
const DATA_VARIANT = 2

var base = "user://dmpb_saves"
var slots = {}
var max_slots = 3
var settings

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


func save_settings(p_data, p_callback):

	ICloud.set_key_values({"settings": p_data})

	if p_callback != null:
		p_callback[0].call_deferred(p_callback[1], OK)

	return OK

func load_settings(p_callback):

	var settings = ICloud.get_key_value("settings")
	if settings == null:
		settings = {}

	p_callback[0].call_deferred(p_callback[1], settings)

	return OK

func _get_as_string(p_arr):
	# find a way to do this faster
	var ret = ""
	for s in p_arr:
		ret += s

	return ret

func save_game(p_data, p_slot, p_callback):

	if p_slot < 0 || p_slot >= max_slots:
		return FAILED

	if typeof(p_data) != typeof(""):
		p_data = _get_as_string(p_data)

	var fname = _get_fname(p_slot)

	var skey = "slot_"+str(p_slot)
	var path = str(base) + "/" + str(fname)
	var vals = {}
	vals[skey] = { "fname": path, "data": p_data }
	var ret = ICloud.set_key_values(vals)

	if typeof(p_callback) != typeof(null):
		p_callback[0].call_deferred(p_callback[1], OK)
	return OK

func autosave(p_data, p_callback):
	var data = _get_as_string(p_data)
	var ret = ICloud.set_key_values({"autosave": data})

	var err = OK
	if ret.size() > 0:
		err = FAILED

	if p_callback != null:
		p_callback[0].call_deferred(p_callback[1], err)

	return err


func load_slot(p_slot, p_callback):

	if p_slot < 0 || p_slot >= max_slots:
		return FAILED

	if p_callback == null:
		return FAILED

	var skey = "slot_"+str(p_slot)
	var data = ICloud.get_key_value(skey)

	if data == null:
		return FAILED

	p_callback[0].call_deferred(p_callback[1], data.data)

	return OK

func load_autosave(p_callback):
	if p_callback == null:
		return FAILED

	var data = ICloud.get_key_value("autosave")

	if data == null:
		return FAILED

	p_callback[0].call_deferred(p_callback[1], data)

	return OK

func get_slots_available(p_callback):

	if p_callback == null:
		return FAILED

	var skeys = ["slot_0", "slot_1", "slot_2"]

	for key in skeys:

		var slot = ICloud.get_key_value(key)
		if slot == null:
			continue

		var f = slot.fname
		f = f.get_file()
		var sep = f.find("-")
		var n = int(f.substr(0, sep))
		if n >= max_slots:
			continue

		var t = f.replace(".esc", "")
		t = t.substr(2, t.length()-2)
		var l = t.split(" ")
		if l.size() < 2:
			printt("invalid file for slot", n, slot.fname)
			continue
		var h = l[1]
		var date = l[0]

		slots[n] = { "n": n, "fname": base + "/" + f, "date": date, "hour": h }

	p_callback[0].call_deferred(p_callback[1], slots)

	return OK

func autosave_available():
	var data = ICloud.get_key_value("autosave")
	return data != null

func start():
	ICloud = ProjectSettings.get_setting("ICloud")
	pass
