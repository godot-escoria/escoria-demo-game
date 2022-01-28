# A cache for resources
extends Object
class_name ESCResourceCache

var thread: Thread
var mutex: Mutex
var sem: Semaphore

var queue: Array = []
var pending: Dictionary = {}

signal resource_loading_progress(path, progress)
signal resource_loading_done(path)
signal resource_queue_progress(queue_size)


#warning-ignore:unused_argument
func _lock(caller):
	mutex.lock()

#warning-ignore:unused_argument
func _unlock(caller):
	mutex.unlock()

#warning-ignore:unused_argument
func _post(caller):
	sem.post()

#warning-ignore:unused_argument
func _wait(caller):
	sem.wait()


func queue_resource(path: String, p_in_front: bool = false, p_permanent: bool = false):
	_lock("queue_resource")
	if path in pending:
		_unlock("queue_resource")
		return

	elif ResourceLoader.has(path):
		var res = ResourceLoader.load(path)
		pending[path] = ESCResourceDescriptor.new(res, p_permanent)
		_unlock("queue_resource")
		return
	else:
		var res = ResourceLoader.load_interactive(path)
		res.set_meta("path", path)
		if p_in_front:
			queue.insert(0, res)
		else:
			queue.push_back(res)
		pending[path] = ESCResourceDescriptor.new(res, p_permanent)
		_post("queue_resource")
		_unlock("queue_resource")
		return

func cancel_resource(path):
	_lock("cancel_resource")
	if path in pending:
		if pending[path].res is ResourceInteractiveLoader:
			queue.erase(pending[path].res)
		pending.erase(path)
	_unlock("cancel_resource")

func clear():
	_lock("clear")

	for p in pending.keys():
		if pending[p].permanent:
			continue
		cancel_resource(p)
	#queue = []
	#pending = {}

	_unlock("clear")


func get_progress(path):
	_lock("get_progress")
	var ret = -1
	if path in pending:
		if pending[path].res is ResourceInteractiveLoader:
			ret = float(pending[path].res.get_stage()) / float(pending[path].res.get_stage_count())
		else:
			ret = 1.0
			emit_signal("resource_loading_done", path)
	emit_signal("resource_loading_progress", path, ret)
	_unlock("get_progress")

	return ret

func is_ready(path):
	var ret
	_lock("is_ready")
	if path in pending:
		ret = !(pending[path].res is ResourceInteractiveLoader)
	else:
		ret = false

	_unlock("is_ready")

	return ret

func _wait_for_resource(res, path):
	_unlock("wait_for_resource")
	while true:
		#VisualServer.call("sync") # workaround because sync is a keyword
		VisualServer.force_sync()
		OS.delay_usec(16000) # wait 1 frame
		_lock("wait_for_resource")
		if queue.size() == 0 || queue[0] != res:
			return pending[path].res
		_unlock("wait_for_resource")


func get_resource(path):
	_lock("get_resource")
	if path in pending:
		if pending[path].res is ResourceInteractiveLoader:
			var res = pending[path].res
			if res != queue[0]:
				var pos = queue.find(res)
				queue.remove(pos)
				queue.insert(0, res)

			res = _wait_for_resource(res, path)

			if !pending[path].permanent:
				pending.erase(path)
			_unlock("return")
			return res

		else:
			var res = pending[path].res
			if !pending[path].permanent:
				pending.erase(path)
			_unlock("return")
			return res
	else:
		_unlock("return")
		# We can't use escoria.project_settings_manager here since this method
		# can be called from escoria._init()
		if not ProjectSettings.get_setting("escoria/platform/skip_cache"):
			var res = ResourceLoader.load(path)
			pending[path] = ESCResourceDescriptor.new(res, true)
			return res
		return ResourceLoader.load(path)

func thread_process():
	_wait("thread_process")

	_lock("process")

	while queue.size() > 0:
		var res = queue[0]

		_unlock("process_poll")
		var ret = res.poll()
		_lock("process_check_queue")

		var path = res.get_meta("path")
		if ret == ERR_FILE_EOF || ret != OK:
			printt("finished loading ", path)
			if path in pending: # else it was already retrieved
				pending[res.get_meta("path")].res = res.get_resource()

			queue.erase(res) # something might have been put at the front of the queue while we polled, so use erase instead of remove
			emit_signal("resource_queue_progress", queue.size())

		get_progress(path)

	_unlock("process")

#warning-ignore:unused_argument
func thread_func(u):
	while true:
		thread_process()

func print_progress(p_path, p_progress):
	printt(p_path, "loading", round(p_progress * 100), "%")

func res_loaded(p_path):
	printt("loaded resource", p_path)

func print_queue_progress(p_queue_size):
	printt("queue size:", p_queue_size)

func start():
	mutex = Mutex.new()
	sem = Semaphore.new()
	thread = Thread.new()
	thread.start(self, "thread_func", 0)

	
	## Uncomment these for debug, or wait for someone to implement log levels
	# connect("resource_loading_progress", self, "print_progress")
	# connect("resource_loading_done", self, "res_loaded")
	# connect("resource_queue_progress", self, "print_queue_progress")
