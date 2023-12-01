class_name Mono

var sekai: Sekai
var define: MonoDefine
var layers := []

var position := Vector3(0, 0, 0)

func _into_sekai(psekai: Sekai) -> void:
	sekai = psekai
	define.finalize()

func _outof_sekai() -> void:
	define = null
	sekai = null

func set_define(pdefine: MonoDefine) -> void:
	define = pdefine

func cover(layer_name: StringName, layer: Dictionary) -> void:
	layers.push_front([layer_name, layer])

func uncover(layer_name: StringName) -> void:
	for lidx in layers.size():
		if layers[lidx][0] == layer_name:
			layers.remove_at(lidx)
			return

func call_watcher(key: StringName, value: Variant) -> Variant:
	if getp(key) != value:
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
			var w := int(value[0])
			var bidx := 0
			while bidx < stack.size():
				if w < int(stack[bidx][0]): break
				bidx += 1
			stack.insert(bidx, value)
			return
	putsB(key, value)

func putsL(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			var stack = l[1].get(key)
			if stack != null:
				var w := int(value[0])
				var bidx := 0
				while bidx < stack.size():
					if w < int(stack[bidx][0]): break
					bidx += 1
				stack.insert(bidx, value)
				return
			l[1][key] = [value]
			return

func putsB(key: StringName, value: Variant) -> void:
	if layers.size() > 0:
		var stack = layers[-1][1].get(key)
		if stack != null:
			var w := int(value[0])
			var bidx := 0
			while bidx < stack.size():
				if w < int(stack[bidx][0]): break
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

# accelerator methods

func is_need_collision() -> bool:
	return getpD(&"need_collision", false)

func is_need_route() -> bool:
	return getpD(&"need_route", false)

func will_route(point: Vector2, z_pos: int) -> Mono:
	if floori(position.z) == z_pos:
		if getp(&"routable"):
			var box := getp(&"route_box") as Rect2
			box.position += Vector2(position.x, position.y)
			if box.has_point(point):
				return self
	return null

func will_collide(region: Rect2, z_pos: int) -> Mono:
	if floori(position.z) == z_pos:
		if getp(&"collisible"):
			var box := getp(&"collision_box") as Rect2
			box.position += Vector2(position.x, position.y)
			if box.intersects(region):
				return self
	return null
