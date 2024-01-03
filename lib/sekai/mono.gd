class_name Mono

var sekai: Sekai
var define: MonoDefine

var inited := false
var position := Vector3(0, 0, 0)
var layers := []

func _into_sekai() -> void:
	pass

func _outof_sekai() -> void:
	pass

func _on_init() -> void:
	if not inited:
		inited = true
		emitm(&"on_init")
		emitm(&"on_inited")

func _on_store() -> void:
	emitm(&"on_store")

func _on_restore() -> void:
	emitm(&"on_restore")

func clone() -> Mono:
	var mono := get_script().new() as Mono
	mono.sekai = sekai
	mono.define = define
	mono.inited = inited
	mono.position = position
	mono.layers = layers.duplicate(true)
	return mono

func to_data() -> Dictionary:
	return {
		&"ref": define.ref,
		&"inited": inited,
		&"layers": layers,
	}

func from_data(psekai: Sekai, data: Dictionary) -> void:
	var ref = data[&"ref"]
	define = psekai.get_define_by_ref(ref)
	inited = data[&"inited"]
	layers = data[&"layers"]

func destroy() -> void:
	sekai.remove_mono(self)

func cover(layer_name: StringName, layer: Dictionary) -> void:
	if layers.size() == 0 and layer_name != &"base": cover(&"base", {})
	layers.push_front([layer_name, layer])

func cover_at(pos: int, layer_name: StringName, layer: Dictionary) -> void:
	layers.insert(pos, [layer_name, layer])

func cover_before(tar_name: StringName, layer_name: StringName, layer: Dictionary) -> void:
	for lidx in layers.size():
		if layers[lidx][0] == tar_name:
			layers.insert(lidx, [layer_name, layer])
			return

func cover_after(tar_name: StringName, layer_name: StringName, layer: Dictionary) -> void:
	for lidx in layers.size():
		if layers[lidx][0] == tar_name:
			layers.insert(lidx + 1, [layer_name, layer])
			return

func uncover(layer_name: StringName) -> void:
	for lidx in layers.size():
		if layers[lidx][0] == layer_name:
			layers.remove_at(lidx)
			return

func call_watcher(key: StringName, value: Variant, force := false) -> Variant:
	if force or getp(key) != value:
		var hkey = StringName("on_" + key)
		var handle = define._props.get(hkey)
		if handle != null: value = handle.call(sekai, self, value)
		var lidx = layers.size() - 1
		while lidx >= 0:
			handle = layers[lidx][1].get(hkey)
			if handle != null: value = handle.call(sekai, self, value)
			lidx -= 1
	return value

## get property methods
## [codeblock]
## D -> Default: get with default value
## L -> Layer:   only get on certain layer
## U -> Under:   only get under certain layer
## B -> Base:    only get on base layer
## R -> Raw:     only get on define
## [/codeblock]
func getp(key: StringName) -> Variant:
	for l in layers:
		var v = l[1].get(key)
		if v != null: return v
	return define._props.get(key)

func getpD(key: StringName, default: Variant) -> Variant:
	for l in layers:
		var v = l[1].get(key)
		if v != null: return v
	return define._props.get(key, default)

func getpL(layer_name: StringName, key: StringName) -> Variant:
	for l in layers:
		if l[0] == layer_name:
			var v = l[1].get(key)
			if v != null: return v
			else: return null
	return null

func getpLD(layer_name: StringName, key: StringName, default: Variant) -> Variant:
	for l in layers:
		if l[0] == layer_name:
			var v = l[1].get(key)
			if v != null: return v
			else: return default
	return default

func getpU(layer_name: StringName, key: StringName) -> Variant:
	var lidx := 0
	while lidx < layers.size():
		if layers[lidx][0] == layer_name:
			lidx += 1
			while lidx < layers.size():
				var v = layers[lidx][1].get(key)
				if v != null: return v
				lidx += 1
			return define._props.get(key)
		lidx += 1
	return null

func getpUD(layer_name: StringName, key: StringName, default: Variant) -> Variant:
	var lidx := 0
	while lidx < layers.size():
		if layers[lidx][0] == layer_name:
			lidx += 1
			while lidx < layers.size():
				var v = layers[lidx][1].get(key)
				if v != null: return v
				lidx += 1
			return define._props.get(key, default)
		lidx += 1
	return default

func getpB(key: StringName) -> Variant:
	if layers.size() > 0:
		return layers[-1][1].get(key)
	return null

func getpBD(key: StringName, default: Variant) -> Variant:
	if layers.size() > 0:
		return layers[-1][1].get(key, default)
	return default

func getpR(key: StringName) -> Variant:
	return define._props.get(key)

func getpRD(key: StringName, default: Variant) -> Variant:
	return define._props.get(key, default)

## set property methods
## [codeblock]
## D -> Direct: set without trigger watchers
## L -> Layer:  only set on certain layer
## B -> Base:   only set on base layer
## [/codeblock]
func setp(key: StringName, value: Variant) -> void:
	for l in layers:
		var v = l[1].get(key)
		if v != null:
			if v != value:
				l[1][key] = call_watcher(key, value)
			return
	setpB(key, value)

func setpD(key: StringName, value: Variant) -> void:
	for l in layers:
		var v = l[1].get(key)
		if v != null:
			if v != value:
				l[1][key] = value
			return
	setpBD(key, value)

func setpL(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			l[1][key] = call_watcher(key, value)
			return

func setpLD(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			l[1][key] = value
			return

func setpB(key: StringName, value: Variant) -> void:
	value = call_watcher(key, value)
	if layers.size() > 0:
		layers[-1][1][key] = value
		return
	cover(&"base", {key: value})

func setpBD(key: StringName, value: Variant) -> void:
	if layers.size() > 0:
		layers[-1][1][key] = value
		return
	cover(&"base", {key: value})

## push onto stack methods
## [codeblock]
## L -> Layer: only push on certain layer
## B -> Base:  only push on base layer
## [/codeblock]
func pushs(key: StringName, value: Variant) -> void:
	for l in layers:
		var stack = l[1].get(key)
		if stack != null:
			stack.push_back(value)
			return
	pushsB(key, value)

func pushsL(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			var stack = l[1].get(key)
			if stack != null:
				stack.push_back(value)
				return
			l[1][key] = [value]
			return

func pushsB(key: StringName, value: Variant) -> void:
	if layers.size() > 0:
		var stack = layers[-1][1].get(key)
		if stack != null:
			stack.push_back(value)
			return
		layers[-1][1][key] = [value]
		return
	cover(&"base", {key: [value]})

## pop from stack methods
## [codeblock]
## L -> Layer: only pop on certain layer
## B -> Base:  only pop on base layer
## [/codeblock]
func pops(key: StringName) -> Variant:
	for l in layers:
		var stack = l[1].get(key)
		if stack != null: return stack.pop_back()
	return null

func popsL(layer_name: StringName, key: StringName) -> Variant:
	for l in layers:
		if l[0] == layer_name:
			var stack = l[1].get(key)
			if stack != null: return stack.pop_back()
			return null
	return null

func popsB(key: StringName) -> Variant:
	if layers.size() > 0:
		var stack = layers[-1][1].get(key)
		if stack != null: return stack.pop_back()
	return null

## put key in the sorted place
## [codeblock]
## L -> Layer: only push on certain layer
## B -> Base:  only push on base layer
## [/codeblock]
func puts(key: StringName, value: Variant) -> void:
	for l in layers:
		var stack = l[1].get(key)
		if stack != null:
			var w := float(String(value[0]))
			var bidx := 0
			while bidx < stack.size():
				if w < float(String(stack[bidx][0])): break
				bidx += 1
			stack.insert(bidx, value)
			return
	putsB(key, value)

func putsL(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			var stack = l[1].get(key)
			if stack != null:
				var w := float(String(value[0]))
				var bidx := 0
				while bidx < stack.size():
					if w < float(String(stack[bidx][0])): break
					bidx += 1
				stack.insert(bidx, value)
				return
			l[1][key] = [value]
			return

func putsB(key: StringName, value: Variant) -> void:
	if layers.size() > 0:
		var stack = layers[-1][1].get(key)
		if stack != null:
			var w := float(String(value[0]))
			var bidx := 0
			while bidx < stack.size():
				if w < float(String(stack[bidx][0])): break
				bidx += 1
			stack.insert(bidx, value)
			return
		layers[-1][1][key] = [value]
		return
	cover(&"base", {key: [value]})

## delete from stack methods
## [codeblock]
## L -> Layer: only delete on certain layer
## B -> Base:  only delete on base layer
## [/codeblock]
func dels(key: StringName, head: Variant) -> Variant:
	for l in layers:
		var stack = l[1].get(key)
		if stack != null:
			var idx = stack.size() - 1
			while idx >= 0:
				if stack[idx][0] == head: break
				idx -= 1
			return stack.pop_at(idx)
	return null

func delsL(layer_name: StringName, key: StringName, head: Variant) -> Variant:
	for l in layers:
		if l[0] == layer_name:
			var stack = l[1].get(key)
			if stack != null:
				var idx = stack.size() - 1
				while idx >= 0:
					if stack[idx][0] == head: break
					idx -= 1
				return stack.pop_at(idx)
			return null
	return null

func delsB(key: StringName, head: Variant) -> Variant:
	if layers.size() > 0:
		var stack = layers[-1][1].get(key)
		if stack != null: 
			var idx = stack.size() - 1
			while idx >= 0:
				if stack[idx][0] == head: break
				idx -= 1
			return stack.pop_at(idx)
	return null

## call function methods
## [codeblock]
## R -> Raw:    only call on define
## S -> Single: not batch call stacks
## U -> Usafe:  fail when handle not found
## A -> Async:  call func with await
## [/codeblock]
func emitm(key: StringName) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = data.call(sekai, self)
	elif data is Array:
		for entry in data:
			value = entry[1].call(sekai, self)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data:
				value = entry[1].call(sekai, self)
		elif data is Callable:
			value = data.call(sekai, self)
		lidx -= 1
	return value

func emitmS(key: StringName) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = handle.call(sekai, self)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = handle.call(sekai, self)
		lidx -= 1
	return value

func callm(key: StringName, arg: Variant) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = data.call(sekai, self, arg)
	elif data is Array:
		for entry in data:
			value = entry[1].call(sekai, self, arg)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data:
				value = entry[1].call(sekai, self, arg)
		elif data is Callable:
			value = data.call(sekai, self, arg)
		lidx -= 1
	return value

func callmS(key: StringName, arg: Variant) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = handle.call(sekai, self, arg)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = handle.call(sekai, self, arg)
		lidx -= 1
	return value

func applym(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = data.callv(vargv)
	elif data is Array:
		for entry in data:
			value = entry[1].callv(vargv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data:
				value = entry[1].callv(vargv)
		elif data is Callable:
			value = data.callv(vargv)
		lidx -= 1
	return value

func applymS(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = handle.callv(vargv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = handle.callv(vargv)
		lidx -= 1
	return value

func emitmR(key: StringName) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = data.call(sekai, self)
	elif data is Array:
		for entry in data:
			value = entry[1].call(sekai, self)
	return value

func emitmRS(key: StringName) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return handle.call(sekai, self)
	return null

func emitmRSU(key: StringName) -> Variant:
	return define._props[key].call(sekai, self)

func callmR(key: StringName, arg: Variant) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = data.call(sekai, self, arg)
	elif data is Array:
		for entry in data:
			value = entry[1].call(sekai, self, arg)
	return value

func callmRS(key: StringName, arg: Variant) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return handle.call(sekai, self, arg)
	return null

func callmRSU(key: StringName, arg: Variant) -> Variant:
	return define._props[key].call(sekai, self, arg)

func applymR(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = data.callv(vargv)
	elif data is Array:
		for entry in data:
			value = entry[1].callv(vargv)
	return value

func applymRS(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var handle = define._props.get(key)
	if handle != null: return handle.callv(vargv)
	return null

func applymRSU(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	return define._props[key].callv(vargv)

func emitmA(key: StringName) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(sekai, self)
	elif data is Array:
		for entry in data:
			value = await entry[1].call(sekai, self)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data:
				value = await entry[1].call(sekai, self)
		elif data is Callable:
			value = await data.call(sekai, self)
		lidx -= 1
	return value

func emitmAS(key: StringName) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await handle.call(sekai, self)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await handle.call(sekai, self)
		lidx -= 1
	return value

func callmA(key: StringName, arg: Variant) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(sekai, self, arg)
	elif data is Array:
		for entry in data:
			value = await entry[1].call(sekai, self, arg)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data:
				value = await entry[1].call(sekai, self, arg)
		elif data is Callable:
			value = await data.call(sekai, self, arg)
		lidx -= 1
	return value

func callmAS(key: StringName, arg: Variant) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await handle.call(sekai, self, arg)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await handle.call(sekai, self, arg)
		lidx -= 1
	return value

func applymA(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.callv(vargv)
	elif data is Array:
		for entry in data:
			value = await entry[1].callv(vargv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data:
				value = await entry[1].callv(vargv)
		elif data is Callable:
			value = await data.callv(vargv)
		lidx -= 1
	return value

func applymAS(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await handle.callv(vargv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await handle.callv(vargv)
		lidx -= 1
	return value

func emitmAR(key: StringName) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(sekai, self)
	elif data is Array:
		for entry in data:
			value = await entry[1].call(sekai, self)
	return value

func emitmARS(key: StringName) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return await handle.call(sekai, self)
	return null

func emitmARSU(key: StringName) -> Variant:
	return await define._props[key].call(sekai, self)

func callmAR(key: StringName, arg: Variant) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(sekai, self, arg)
	elif data is Array:
		for entry in data:
			value = await entry[1].call(sekai, self, arg)
	return value

func callmARS(key: StringName, arg: Variant) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return await handle.call(sekai, self, arg)
	return null

func callmARSU(key: StringName, arg: Variant) -> Variant:
	return await define._props[key].call(sekai, self, arg)

func applymAR(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.callv(vargv)
	elif data is Array:
		for entry in data:
			value = await entry[1].callv(vargv)
	return value

func applymARS(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var handle = define._props.get(key)
	if handle != null: return await handle.callv(vargv)
	return null

func applymARSU(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	return await define._props[key].callv(vargv)

# accelerator methods

func is_need_collision() -> bool:
	return getpD(&"need_collision", false)

func is_need_route() -> bool:
	return getpD(&"need_route", false)

func will_route(point: Vector2, z_pos: int, result: Array) -> void:
	if floori(position.z) == z_pos:
		if getp(&"routable"):
			var box := getp(&"route_box") as Rect2
			box.position += Vector2(position.x, position.y)
			if box.has_point(point):
				result.append(self)

func will_collide(region: Rect2, z_pos: int, result: Array) -> void:
	if floori(position.z) == z_pos:
		if getp(&"collisible"):
			var box := getp(&"collision_box") as Rect2
			box.position += Vector2(position.x, position.y)
			if box.intersects(region):
				result.append(self)
