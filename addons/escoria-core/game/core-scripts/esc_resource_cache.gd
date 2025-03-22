## A cache for resources
extends Node
class_name ESCResourceCache


signal resource_loading_progress(path, progress)
signal resource_loading_done(path)
signal resource_queue_progress(queue_size)


var queue: Array = []
var pending: Dictionary = {}


func _ready():
	name = "resource_cacher"
	resource_loading_progress.connect(print_progress)
	resource_loading_done.connect(res_loaded)
	resource_queue_progress.connect(print_queue_progress)


func queue_resource(path: String, p_in_front: bool = false, p_permanent: bool = false):
	if path in pending:
		return

	elif ResourceLoader.has_cached(path):
		var res = ResourceLoader.load(path)
		pending[path] = ESCResourceDescriptor.new(res, p_permanent)
	else:
		var res = ResourceLoader.load_threaded_request(path)
		res.resource_path = path
		if p_in_front:
			queue.insert(0, res)
		else:
			queue.push_back(res)
		pending[path] = ESCResourceDescriptor.new(res, p_permanent)


func cancel_resource(path):
	if path in pending:
		if pending[path].res is ResourceLoader:
			queue.erase(pending[path].res)
		pending.erase(path)


func clear():
	for p in pending.keys():
		if pending[p].permanent:
			continue
		cancel_resource(p)
	#queue = []
	#pending = {}


func get_progress(path):
	var ret = -1
	if path in pending:
		if pending[path].res is ResourceLoader:
			ret = float(pending[path].res.get_stage()) / float(pending[path].res.get_stage_count())
		else:
			ret = 1.0
			resource_loading_done.emit(path)
	resource_loading_progress.emit(path, ret)

	return ret


func is_ready(path):
	var ret

	if path in pending:
		ret = !(pending[path].res is ResourceLoader)
	else:
		ret = false

	return ret


func _wait_for_resource(res, path):
	while true:
		#VisualServer.call("sync") # workaround because sync is a keyword
		RenderingServer.force_sync()
		OS.delay_usec(16000) # wait 1 frame

		if queue.size() == 0 || queue[0] != res:
			return pending[path].res


func get_resource(path):
	if path in pending:
		if pending[path].res is ResourceLoader:
			var res = pending[path].res
			if res != queue[0]:
				var pos = queue.find(res)
				queue.remove_at(pos)
				queue.insert(0, res)

			res = _wait_for_resource(res, path)

			if !pending[path].permanent:
				pending.erase(path)

			return res

		else:
			var res = pending[path].res
			if !pending[path].permanent:
				pending.erase(path)

			return res
	else:
		# We can't use ESCProjectSettingsManager here since this method
		# can be called from escoria._init()
		if not ProjectSettings.get_setting("escoria/platform/skip_cache"):
			var res = ResourceLoader.load(path)
			pending[path] = ESCResourceDescriptor.new(res, true)
			return res
		return ResourceLoader.load(path)


func print_progress(p_path, p_progress):
	escoria.logger.info(self, "{0} loading: {1}%".format([p_path, round(p_progress * 100)]))


func res_loaded(p_path):
	escoria.logger.info(self, "loaded resource: {0}%".format([p_path]))


func print_queue_progress(p_queue_size):
	escoria.logger.info(self, "queue size: {0}%".format([p_queue_size]))


func _process(_delta) -> void:
	while queue.size() > 0:
		var res = queue[0]

		var ret = res.poll()

		var path = res.get_meta("path")
		if ret == ERR_FILE_EOF || ret != OK:
			escoria.logger.info(self, "Finished loading %s" % path)
			if path in pending: # else it was already retrieved
				pending[res.get_meta("path")].res = res.get_resource()

			queue.erase(res) # something might have been put at the front of the queue while we polled, so use erase instead of remove
			resource_queue_progress.emit(queue.size())
