class_name Mono
## Sekai 内使用的基本实例类型

var root: Mono = null
var define: MonoDefine

var inited := false
var ready := false
var position := Vector3(0, 0, 0)
var layers := []

static func to_data(mono: Mono) -> Variant:
	return mono._to_data()

static func store_to_data(ctx: LisperContext, mono: Mono) -> Variant:
	await mono.store(ctx)
	return to_data(mono)

static func from_data(data: Variant) -> Mono:
	var mono := Mono.new()
	mono._from_data(data)
	return mono

static func restore_from_data(ctx: LisperContext, data: Variant) -> Mono:
	var mono := from_data(data)
	await mono.restore(ctx)
	return mono

class FnVal: pass

static func clone_val(value: Variant) -> Variant:
	if Lisper.is_fn(value):
		return FnVal.new()
	if value is Object:
		return null
	if value is Array:
		var res := []
		for rv in value:
			var v = clone_val(rv)
			if v is FnVal:
				return null
			if v == null:
				continue
			res.append(v)
		return res
	if value is Dictionary:
		var res := {}
		for k in value.keys():
			var v = clone_val(value[k])
			if v != null and not v is FnVal:
				res[k] = v
		return res
	return value

func _into_container(ctx: LisperContext, cont: Mono) -> void:
	root = cont
	if root.inited: await init(ctx)

func _outof_container() -> void:
	root = null

func init(ctx: LisperContext) -> void:
	if not inited:
		inited = true
		await emitc(ctx, &"on_init")
		await emitc(ctx, &"on_inited")
		await emitc(ctx, &"on_ready")

func store(ctx: LisperContext) -> void:
	await emitc(ctx, &"on_store")

func restore(ctx: LisperContext) -> void:
	await emitc(ctx, &"on_restore")
	await emitc(ctx, &"on_ready")

func clone() -> Mono:
	var mono := get_script().new() as Mono
	mono.define = define
	mono.inited = inited
	mono.position = position
	mono.layers = layers.duplicate(true)
	return mono

func clone_data() -> Mono:
	var mono := get_script().new() as Mono
	mono.define = define
	mono.inited = inited
	mono.position = position
	mono.layers = Mono.clone_val(layers)
	return mono

func _to_data() -> Dictionary:
	return {
		&"ref": define.ref,
		&"inited": inited,
		&"layers": layers.duplicate(true),
	}

func _from_data(data: Dictionary) -> void:
	var ref = data[&"ref"]
	define = sekai.get_define(ref)
	inited = data[&"inited"]
	layers = data[&"layers"]

func remove(ctx: LisperContext) -> Mono:
	if root != null:
		root.callm(ctx, &"container/pick", self)
	return self

func get_hako() -> Mono:
	if root != null:
		if root.define.id == &"hako":
			return root
		else:
			return root.get_hako()
	return null

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

func call_watcher(ctx: LisperContext, key: StringName, value: Variant, force := false) -> Variant:
	if force or getp(key) != value:
		var hkey = StringName("on_" + key)
		var data = define._props.get(hkey)
		if data is Callable:
			value = await data.call(ctx, self, value)
		elif data is Array:
			for entry in data.duplicate():
				value = await entry[1].call(ctx, self, value)
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

func getpBR(key: StringName) -> Variant:
	if layers.size() > 0:
		return layers[-1][1].get(key, define._props.get(key))
	return define._props.get(key)

func getpBD(key: StringName, default: Variant) -> Variant:
	if layers.size() > 0:
		return layers[-1][1].get(key, default)
	return default

func getpBRD(key: StringName, default: Variant) -> Variant:
	if layers.size() > 0:
		return layers[-1][1].get(key, define._props.get(key, default))
	return define._props.get(key, default)

func getpR(key: StringName) -> Variant:
	return define._props.get(key)

func getpRD(key: StringName, default: Variant) -> Variant:
	return define._props.get(key, default)

## set property methods
## [codeblock]
## W -> Watcher:set with watchers triggered
## F -> Force:  set with watchers triggered forced
## L -> Layer:  only set on certain layer
## B -> Base:   only set on base layer
## R -> Raw:    only set on define (Direct)
## [/codeblock]
func setp(key: StringName, value: Variant) -> void:
	for l in layers:
		var v = l[1].get(key)
		if v != null:
			if v != value:
				l[1][key] = value
			return
	setpB(key, value)

func setpW(ctx: LisperContext, key: StringName, value: Variant) -> void:
	for l in layers:
		var v = l[1].get(key)
		if v != null:
			if v != value:
				l[1][key] = await call_watcher(ctx, key, value)
			await callm(ctx, StringName("after_" + key), value)
			await applym(ctx, &"on_mod", [key, value])
			return
	setpBW(ctx, key, value)

func setpF(ctx: LisperContext, key: StringName, value: Variant) -> void:
	for l in layers:
		var v = l[1].get(key)
		if v != null:
			if v != value:
				l[1][key] = await call_watcher(ctx, key, value, true)
			await callm(ctx, StringName("after_" + key), value)
			await applym(ctx, &"on_mod", [key, value])
			return
	setpBF(ctx, key, value)

func setpL(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			l[1][key] = value
			return

func setpLW(ctx: LisperContext, layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			l[1][key] = await call_watcher(ctx, key, value)
			await callm(ctx, StringName("after_" + key), value)
			await applym(ctx, &"on_mod", [key, value])
			return

func setpLF(ctx: LisperContext, layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			l[1][key] = await call_watcher(ctx, key, value, true)
			await callm(ctx, StringName("after_" + key), value)
			await applym(ctx, &"on_mod", [key, value])
			return

func setpB(key: StringName, value: Variant) -> void:
	if layers.size() > 0:
		layers[-1][1][key] = value
		return
	cover(&"base", {key: value})

func setpBW(ctx: LisperContext, key: StringName, value: Variant) -> void:
	value = await call_watcher(ctx, key, value)
	if layers.size() > 0:
		layers[-1][1][key] = value
		await callm(ctx, StringName("after_" + key), value)
		await applym(ctx, &"on_mod", [key, value])
		return
	cover(&"base", {key: value})
	await callm(ctx, StringName("after_" + key), value)
	await applym(ctx, &"on_mod", [key, value])

func setpBF(ctx: LisperContext, key: StringName, value: Variant) -> void:
	value = await call_watcher(ctx, key, value, true)
	if layers.size() > 0:
		layers[-1][1][key] = value
		await callm(ctx, StringName("after_" + key), value)
		await applym(ctx, &"on_mod", [key, value])
		return
	cover(&"base", {key: value})
	await callm(ctx, StringName("after_" + key), value)
	await applym(ctx, &"on_mod", [key, value])

func setpR(key: StringName, value: Variant) -> void:
	define._props[key] = value

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
## Y -> Sync:   call without async
## [/codeblock]
func emitm(ctx: LisperContext, key: StringName) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(ctx, self)
	elif data is Array:
		for entry in data.duplicate():
			value = await entry[1].call(ctx, self)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data.duplicate():
				value = await entry[1].call(ctx, self)
		elif data is Callable:
			value = await data.call(ctx, self)
		lidx -= 1
	return value

func emitmS(ctx: LisperContext, key: StringName) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await handle.call(ctx, self)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await handle.call(ctx, self)
		lidx -= 1
	return value

func emitmR(ctx: LisperContext, key: StringName) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(ctx, self)
	elif data is Array:
		for entry in data.duplicate():
			value = await entry[1].call(ctx, self)
	return value

func emitmRS(ctx: LisperContext, key: StringName) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return await handle.call(ctx, self)
	return null

func emitmRSU(ctx: LisperContext, key: StringName) -> Variant:
	return await define._props[key].call(ctx, self)

func emitmRSUY(ctx: LisperContext, key: StringName) -> Variant:
	return define._props[key].call(ctx, self)

func callm(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(ctx, self, arg)
	elif data is Array:
		for entry in data.duplicate():
			value = await entry[1].call(ctx, self, arg)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data.duplicate():
				value = await entry[1].call(ctx, self, arg)
		elif data is Callable:
			value = await data.call(ctx, self, arg)
		lidx -= 1
	return value

func callmS(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await handle.call(ctx, self, arg)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await handle.call(ctx, self, arg)
		lidx -= 1
	return value

func callmR(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(ctx, self, arg)
	elif data is Array:
		for entry in data.duplicate():
			value = await entry[1].call(ctx, self, arg)
	return value

func callmRS(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return await handle.call(ctx, self, arg)
	return null

func callmRSU(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	return await define._props[key].call(ctx, self, arg)

func callmRSUY(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	return define._props[key].call(ctx, self, arg)

func applym(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	var vargv := [ctx, self]
	vargv.append_array(argv)
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.callv(vargv)
	elif data is Array:
		for entry in data.duplicate():
			value = await entry[1].callv(vargv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data.duplicate():
				value = await entry[1].callv(vargv)
		elif data is Callable:
			value = await data.callv(vargv)
		lidx -= 1
	return value

func applymS(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	var vargv := [ctx, self]
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

func applymR(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	var vargv := [ctx, self]
	vargv.append_array(argv)
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.callv(vargv)
	elif data is Array:
		for entry in data.duplicate():
			value = await entry[1].callv(vargv)
	return value

func applymRS(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	var vargv := [ctx, self]
	vargv.append_array(argv)
	var handle = define._props.get(key)
	if handle != null: return await handle.callv(vargv)
	return null

func applymRSU(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	var vargv := [ctx, self]
	vargv.append_array(argv)
	return await define._props[key].callv(vargv)

func applymRSUY(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	var vargv := [ctx, self]
	vargv.append_array(argv)
	return define._props[key].callv(vargv)

## call lisper function methods
## [codeblock]
## R -> Raw:    only call on define
## S -> Single: not batch call stacks
## U -> Usafe:  fail when handle not found
## [/codeblock]
func emitc(ctx: LisperContext, key: StringName) -> Variant:
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_method(self, data)
	elif data is Array:
		for entry in data.duplicate():
			value = await ctx.call_method(self, entry[1])
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if Lisper.is_fn(data):
			value = await ctx.call_method(self, data)
		elif data is Array:
			for entry in data.duplicate():
				value = await ctx.call_method(self, entry[1])
		lidx -= 1
	return value

func emitcS(ctx: LisperContext, key: StringName) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await ctx.call_method(self, handle)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await ctx.call_method(self, handle)
		lidx -= 1
	return value

func emitcR(ctx: LisperContext, key: StringName) -> Variant:
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_method(self, data)
	elif data is Array:
		for entry in data.duplicate():
			value = await ctx.call_method(self, entry[1])
	return value

func emitcRS(ctx: LisperContext, key: StringName) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return await ctx.call_method(self, handle)
	return null

func emitcRSU(ctx: LisperContext, key: StringName) -> Variant:
	return await ctx.call_method(self, define._props[key])

func callc(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_method(self, data, [arg])
	elif data is Array:
		for entry in data.duplicate():
			value = await ctx.call_method(self, entry[1], [arg])
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if Lisper.is_fn(data):
			value = await ctx.call_method(self, data, [arg])
		elif data is Array:
			for entry in data.duplicate():
				value = await ctx.call_method(self, entry[1], [arg])
		lidx -= 1
	return value

func callcS(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await ctx.call_method(self, handle, [arg])
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await ctx.call_method(self, handle, [arg])
		lidx -= 1
	return value

func callcR(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_method(self, data, [arg])
	elif data is Array:
		for entry in data.duplicate():
			value = await ctx.call_method(self, entry[1], [arg])
	return value

func callcRS(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return await ctx.call_method(self, handle, [arg])
	return null

func callcRSU(ctx: LisperContext, key: StringName, arg: Variant) -> Variant:
	return await ctx.call_method(self, define._props[key], [arg])

func applyc(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_method(self, data, argv)
	elif data is Array:
		for entry in data.duplicate():
			value = await ctx.call_method(self, entry[1], argv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if Lisper.is_fn(data):
			value = await ctx.call_method(self, data, argv)
		elif data is Array:
			for entry in data.duplicate():
				value = await ctx.call_method(self, entry[1], argv)
		lidx -= 1
	return value

func applycS(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await ctx.call_method(self, handle, argv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await ctx.call_method(self, handle, argv)
		lidx -= 1
	return value

func applycR(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_method(self, data, argv)
	elif data is Array:
		for entry in data.duplicate():
			value = await ctx.call_method(self, entry[1], argv)
	return value

func applycRS(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return await ctx.call_method(self, handle, argv)
	return null

func applycRSU(ctx: LisperContext, key: StringName, argv: Array) -> Variant:
	return await ctx.call_method(self, define._props[key], argv)

## call lisper raw function methods
## [codeblock]
## R -> Raw:    only call on define
## S -> Single: not batch call stacks
## U -> Usafe:  fail when handle not found
## [/codeblock]
func applyr(ctx: LisperContext, key: StringName, body: Array) -> Variant:
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_method_raw(self, data, body)
	elif data is Array:
		for entry in data.duplicate():
			value = await ctx.call_method_raw(self, entry[1], body)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if Lisper.is_fn(data):
			value = await ctx.call_method_raw(self, data, body)
		elif data is Array:
			for entry in data.duplicate():
				value = await ctx.call_method_raw(self, entry[1], body)
		lidx -= 1
	return value

func applyrS(ctx: LisperContext, key: StringName, body: Array) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await ctx.call_method_raw(self, handle, body)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await ctx.call_method_raw(self, handle, body)
		lidx -= 1
	return value

func applyrR(ctx: LisperContext, key: StringName, body: Array) -> Variant:
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_method_raw(self, data, body)
	elif data is Array:
		for entry in data.duplicate():
			value = await ctx.call_method_raw(self, entry[1], body)
	return value

func applyrRS(ctx: LisperContext, key: StringName, body: Array) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return await ctx.call_method_raw(self, handle, body)
	return null

func applyrRSU(ctx: LisperContext, key: StringName, body: Array) -> Variant:
	return await ctx.call_method_raw(self, define._props[key], body)



func gsm(): return ['

defunc (do :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var act_name := await ctx.exec_as_keyword(body[1]) as StringName
			return await this.applyr(ctx, act_name, body.slice(2))
,')

defunc (callm :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var method := await ctx.exec_as_keyword(body[1]) as StringName
			var argv := await ctx.execs(body.slice(2)) as Array
			return await this.applym(ctx, method, argv)
,')

defunc (getp :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var key := await ctx.exec_as_keyword(body[1]) as StringName
			return this.getp(key)
,')

defunc (setp :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var key := await ctx.exec_as_keyword(body[1]) as StringName
			var value = await ctx.exec(body[2])
			this.setp(key, value)
			return this
,')

defunc (puts :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var key := await ctx.exec_as_keyword(body[1]) as StringName
			var pairs := body[2][1] as Array
			for i in pairs.size() / 2:
				var k := await ctx.exec_as_keyword(pairs[2 * i]) as StringName
				var v = await ctx.exec(pairs[2 * i + 1])
				this.puts(key, [k, v])
			return this
,')

defunc (dels :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var key := await ctx.exec_as_keyword(body[1]) as StringName
			var head = await ctx.exec(body[2])
			this.dels(key, head)
			return this
,')

defunc (listen :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		var this = body[0]
		var key = body[1]
		var head = body[2]
		var args = body[3]
		var chunk = body.slice(4)
		return Lisper.apply(&"puts", [[this, key, Lisper.Map([
			head, Lisper.apply(&"func", [[args], chunk])
		])]])
,')

defunc (unlisten :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var key := await ctx.exec_as_keyword(body[1]) as StringName
			var head = await ctx.exec(body[2])
			this.dels(key, head)
			return this
,')

defunc (wait :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		var this = body[0]
		var key = body[1]
		var args = body[2]
		var head = Lisper.String(str(sekai.get_uidx()))
		var chunk = body.slice(3)
		return Lisper.apply(&"puts", [[this, key, Lisper.Map([
			head, Lisper.apply(&"func", [[args,
				Lisper.apply(&"unlisten", [[this, key, head]])
			], chunk])
		])]])
,')

defunc (remove :const :gd :apply ', func (ctx: LisperContext, args: Array): args[0].remove(ctx) ,')
defunc (queue_remove :const :gd ', func (this: Mono): this.remove.call_deferred() ,')

']
