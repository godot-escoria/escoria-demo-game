var global = null
var current_context

func check_obj(name, cmd):
	var obj = vm.get_object(name)
	if obj == null:
		vm.report_errors("", ["Global id "+name+" not found for " + cmd])
		return false
	return true

func _slide(params, block):
	if !check_obj(params[0], "slide"):
		return vm.state_return
	if !check_obj(params[1], "slide"):
		return vm.state_return
	var tpos = vm.get_object(params[1]).get_interact_pos()
	var speed = 0
	if params.size() > 2:
		speed = real(params[2])
	if block:
		current_context.waiting = true
		vm.get_object(params[0]).slide(tpos, speed, current_context)
		return vm.state_yield
	else:
		vm.get_object(params[0]).slide(tpos, speed)
		return vm.state_return

func _walk(params, block):
	if !check_obj(params[0], "walk"):
		return vm.state_return
	if !check_obj(params[1], "walk"):
		return vm.state_return
	var tpos = vm.get_object(params[1]).get_interact_pos()
	var speed = 0
	if params.size() > 2:
		speed = real(params[2])
	if block:
		current_context.waiting = true
		vm.get_object(params[0]).walk(tpos, speed, current_context)
		return vm.state_yield
	else:
		vm.get_object(params[0]).walk(tpos, speed)
		return vm.state_return

### commands

func set_global(params):
	vm.set_global(params[0], params[1])
	return vm.state_return

func dec_global(params):
	vm.dec_global(params[0], params[1])
	return vm.state_return

func inc_global(params):
	vm.inc_global(params[0], params[1])
	return vm.state_return

func debug(params):
	for p in params:
		printt(p)
	return vm.state_return

func anim(params):
	if !check_obj(params[0], "anim"):
		return vm.state_return
	var obj = vm.get_object(params[0])
	var anim_id = params[1]
	var reverse = false
	if params.size() > 2:
		reverse = params[2]
	var flip = Vector2(1, 1)
	if params.size() > 3 && params[3]:
		flip.x = -1
	if params.size() > 4 && params[4]:
		flip.y = -1
	obj.play_anim(anim_id, null, reverse, flip)
	return vm.state_return

func play_snd(params):
	if !check_obj(params[0], "play_snd"):
		return vm.state_return
	var obj = vm.get_object(params[0])
	var snd_id = params[1]
	obj.play_snd(snd_id)
	return vm.state_return

func set_state(params):
	var obj = vm.get_object(params[0])
	if obj != null:
		obj.set_state(params[1])
	vm.set_state(params[0], params[1])
	return vm.state_return

func set_hud_visible(params):
	vm.set_hud_visible(params[0])

func set_tooltip_visible(params):
	vm.set_tooltip_visible(params[0])

func say(params):
	if !check_obj(params[0], "say"):
		return vm.state_return
	current_context.waiting = true
	vm.say(params, current_context)
	return vm.state_yield

func dialog(params):
	current_context.waiting = true
	current_context.in_dialog = true
	vm.dialog(params, current_context)
	return vm.state_yield

func end_dialog(params):
	current_context.in_dialog = false
	vm.end_dialog(params)

func cut_scene(params):
	if !check_obj(params[0], "cut_scene"):
		return vm.state_return
	var obj = vm.get_object(params[0])
	var anim_id = params[1]
	var reverse = false
	if params.size() > 2:
		reverse = params[2]
	var flip = Vector2(1, 1)
	if params.size() > 3 && params[3]:
		flip.x = -1
	if params.size() > 4 && params[4]:
		flip.y = -1
	current_context.waiting = true
	obj.play_anim(anim_id, current_context, reverse, flip)
	return vm.state_yield

func branch(params):
	var branch_ev = vm.compiler.EscoriaEvent.new("branch", params, [])

	return vm.add_level(branch_ev, false)

func inventory_add(params):
	vm.inventory_set(params[0], true)
	return vm.state_return

func inventory_remove(params):
	vm.inventory_set(params[0], false)
	return vm.state_return

func inventory_open(params):
	vm.emit_signal("open_inventory", params[0])

func set_active(params):
	var obj = vm.get_object(params[0])
	if obj != null:
		obj.set_active(params[1])
	vm.set_active(params[0], params[1])
	return vm.state_return

func stop(params):
	return vm.state_break

func repeat(params):
	return vm.state_repeat

func wait(params):
	return vm.wait(params, current_context)

func set_use_action_menu(params):
	var obj = vm.get_object(params[0])
	vm.set_use_action_menu(obj, params[1])

func set_speed(params):
	var obj = vm.get_object(params[0])
	vm.set_speed(obj, params[1])

func teleport(params):
	if !check_obj(params[0], "teleport"):
		return vm.state_return
	if !check_obj(params[1], "teleport"):
		return vm.state_return
	vm.get_object(params[0]).teleport(vm.get_object(params[1]))
	return vm.state_return

func teleport_pos(params):
	if !check_obj(params[0], "teleport_pos"):
		return vm.state_return
	vm.get_object(params[0]).teleport_pos(int(params[1]), int(params[2]))
	return vm.state_return


func slide(params):
	return _slide(params, false)

func slide_block(params):
	return _slide(params, true)

func walk(params):
	return _walk(params, false)

func walk_block(params):
	return _walk(params, true)

func turn_to(params):
	var obj = vm.get_object(params[0])
	obj.turn_to(int(params[1]))
	return vm.state_return

func set_angle(params):
	var obj = vm.get_object(params[0])
	obj.set_angle(int(params[1]))
	return vm.state_return

func change_scene(params):
	# Savegames must have events disabled, so saving the game adds a false to params
	var run_events = true
	if params.size() == 2:
		run_events = bool(params[1])

	# looking for localized string format in scene. this should be somewhere else
	var sep = params[0].find(":\"")
	if sep >= 0:
		var path = params[0].substr(sep + 2, params[0].length() - (sep + 2))
		vm.call_deferred("change_scene", [path], current_context, run_events)
	else:
		vm.call_deferred("change_scene", params, current_context, run_events)

	current_context.waiting = true
	return vm.state_yield

func spawn(params):
	return vm.spawn(params)

func jump(params):
	vm.jump(params[0])
	return vm.state_jump

func dialog_config(params):
	vm.dialog_config(params)
	return vm.state_return

func sched_event(params):
	var time = params[0]
	var obj = params[1]
	var event
	if params.size() == 3:
		event = params[2]
	else:
		# This should be easier in Godot 3.1 with array slicing
		for i in range(2, params.size()):
			var word = params[i]
			if not event:
				event = word
			else:
				event += " %s" % word

	if !check_obj(obj, "sched_event"):
		return
	var o = vm.get_object(obj)
	if !(event in o.event_table):
		vm.report_errors("", ["Event "+event+" not found on object " + obj + " for sched_event."])
		return
	vm.sched_event(time, obj, event)

func custom(params):
	var node = vm.get_node(params[0])
	if node == null:
		vm.report_errors("", ["Node not found for custom: "+params[0]])

	if params.size() > 2:
		node.call(params[1], params)
	else:
		node.call(params[1])

func camera_set_target(params):
	var speed = params[0]
	var targets = []
	for i in range(1, params.size()):
		targets.push_back(params[i])
	vm.camera_set_target(speed, targets)

func camera_set_pos(params):
	var speed = params[0]
	var pos = Vector2(params[1], params[2])
	vm.camera_set_target(speed, pos)

func camera_set_zoom(params):
	var magnitude = params[0]
	var time = params[1] if params.size() > 1 else 0
	vm.camera_set_zoom(magnitude, float(time))

func camera_set_zoom_height(params):
	var magnitude = params[0] / vm.game_size.y
	var time = params[1] if params.size() > 1 else 0
	vm.camera_set_zoom(magnitude, float(time))

func set_globals(params):
	var pat = params[0]
	var val = params[1]
	vm.set_globals(pat, val)

func autosave(params):
	vm.request_autosave()

func queue_resource(params):
	var path = params[0]
	var in_front = false
	if params.size() > 1:
		in_front = params[1]

	vm.res_cache.queue_resource(path, in_front)

func queue_animation(params):
	var obj = params[0]
	var anim = params[1]
	var in_front = false
	if params.size() > 2:
		in_front = params[2]

	if !check_obj(obj, "queue_animation"):
		return vm.state_return

	obj = vm.get_object(obj)
	var paths = obj.anim_get_ph_paths(anim)
	for p in paths:
		vm.res_cache.queue_resource(p, in_front)

	return vm.state_return

func game_over(params):
	var continue_enabled = params[0]
	var show_credits = false
	if params.size() > 1:
		show_credits = params[1]
	vm.call_deferred("game_over", continue_enabled, show_credits, current_context)
	current_context.waiting = true
	return vm.state_yield

### end command

func run(context):
	var cmd = context.instructions[context.ip]
	if cmd.name == "label":
		return vm.state_return
	if !vm.test(cmd):
		return vm.state_return
	#print("name is ", cmd.name)
	#if !(cmd.name in self):
	#	vm.report_errors("", ["Unexisting command "+cmd.name])

	return call(cmd.name, cmd.params)

func resume(context):
	current_context = context
	if context.waiting:
		return vm.state_yield
	var count = context.instructions.size()
	while context.ip < count:
		var top = vm.stack.size()
		var ret = run(context)
		context.ip += 1
		if top < vm.stack.size():
			return vm.state_call
		if ret == vm.state_yield:
			return vm.state_yield
		if ret == vm.state_call:
			return vm.state_call
		if ret == vm.state_break:
			if context.break_stop:
				break
			else:
				return vm.state_break
		if ret == vm.state_repeat:
			context.ip = 0
		if ret == vm.state_jump:
			return vm.state_jump
	context.ip = 0
	return vm.state_return

func set_vm(p_vm):
	vm = p_vm
