class_name Async

static func array_map(ary: Array, handle: Callable) -> Array:
	var res := ary.map(handle)
	for i in res.size(): res[i] = await res[i]
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
