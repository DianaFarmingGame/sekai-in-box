class_name Async

static func array_map(ary: Array, handle: Callable) -> Array:
	var res := []
	res.resize(ary.size())
	for i in ary.size():
		res[i] = await handle.call(ary[i])
	return res

static func array_filter(ary: Array, handle: Callable) -> Array:
	var res := []
	for e in ary:
		if await handle.call(e): res.append(e)
	return res

static func array_any(ary: Array, handle: Callable) -> bool:
	for e in ary:
		if await handle.call(e): return true
	return false

static func signal_clear(s: Signal) -> void:
	for conn in s.get_connections():
		s.disconnect(conn[&"callable"])

static func signal_any(list: Array) -> Signal:
	var res := Signal()
	for s in list:
		(s as Signal).connect(func (param = null):
			res.emit(param)
		)
	return res
