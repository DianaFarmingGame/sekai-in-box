class_name Mono

var root = null
var define: MonoDefine

var inited := false
var position := Vector3(0, 0, 0)
var layers := []

static func to_data(mono: Mono) -> Variant:
	await mono.store()
	return mono._to_data()

static func from_data(data: Variant) -> Mono:
	var mono := Mono.new()
	mono._from_data(data)
	await mono.restore()
	return mono

func _into_container(cont: Mono) -> void:
	root = cont

func _outof_container() -> void:
	root = null

func _on_init() -> void:
	if not inited:
		inited = true
		await emitm(&"on_init")
		await emitm(&"on_inited")

func store() -> void:
	await emitm(&"on_store")

func restore() -> void:
	await emitm(&"on_restore")

func clone() -> Mono:
	var mono := get_script().new() as Mono
	mono.define = define
	mono.inited = inited
	mono.position = position
	mono.layers = layers.duplicate(true)
	return mono

func _to_data() -> Dictionary:
	return {
		&"ref": define.ref,
		&"inited": inited,
		&"layers": layers,
	}

func _from_data(data: Dictionary) -> void:
	var ref = data[&"ref"]
	define = sekai.get_define_by_ref(ref)
	inited = data[&"inited"]
	layers = data[&"layers"]

func remove() -> Mono:
	if root != null:
		root.callm(&"container/pick", self)
	return self

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
		if handle != null: value = await handle.call(self, value)
		var lidx = layers.size() - 1
		while lidx >= 0:
			handle = layers[lidx][1].get(hkey)
			if handle != null: value = await handle.call(self, value)
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
				l[1][key] = await call_watcher(key, value)
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

func setpF(key: StringName, value: Variant) -> void:
	for l in layers:
		var v = l[1].get(key)
		if v != null:
			if v != value:
				l[1][key] = await call_watcher(key, value, true)
			return
	setpBF(key, value)

func setpL(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			l[1][key] = await call_watcher(key, value)
			return

func setpLD(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			l[1][key] = value
			return

func setpLF(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			l[1][key] = await call_watcher(key, value, true)
			return

func setpB(key: StringName, value: Variant) -> void:
	value = await call_watcher(key, value)
	if layers.size() > 0:
		layers[-1][1][key] = value
		return
	cover(&"base", {key: value})

func setpBD(key: StringName, value: Variant) -> void:
	if layers.size() > 0:
		layers[-1][1][key] = value
		return
	cover(&"base", {key: value})

func setpBF(key: StringName, value: Variant) -> void:
	value = await call_watcher(key, value, true)
	if layers.size() > 0:
		layers[-1][1][key] = value
		return
	cover(&"base", {key: value})

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
## [/codeblock]
func emitm(key: StringName) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(self)
	elif data is Array:
		for entry in data:
			value = await entry[1].call(self)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data:
				value = await entry[1].call(self)
		elif data is Callable:
			value = await data.call(self)
		lidx -= 1
	return value

func emitmS(key: StringName) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await handle.call(self)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await handle.call(self)
		lidx -= 1
	return value

func emitmR(key: StringName) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(self)
	elif data is Array:
		for entry in data:
			value = await entry[1].call(self)
	return value

func emitmRS(key: StringName) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return await handle.call(self)
	return null

func emitmRSU(key: StringName) -> Variant:
	return await define._props[key].call(self)

func callm(key: StringName, arg: Variant) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(self, arg)
	elif data is Array:
		for entry in data:
			value = await entry[1].call(self, arg)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if data is Array:
			for entry in data:
				value = await entry[1].call(self, arg)
		elif data is Callable:
			value = await data.call(self, arg)
		lidx -= 1
	return value

func callmS(key: StringName, arg: Variant) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await handle.call(self, arg)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await handle.call(self, arg)
		lidx -= 1
	return value

func callmR(key: StringName, arg: Variant) -> Variant:
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.call(self, arg)
	elif data is Array:
		for entry in data:
			value = await entry[1].call(self, arg)
	return value

func callmRS(key: StringName, arg: Variant) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return await handle.call(self, arg)
	return null

func callmRSU(key: StringName, arg: Variant) -> Variant:
	return await define._props[key].call(self, arg)

func applym(key: StringName, argv: Array) -> Variant:
	var vargv := [self]
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

func applymS(key: StringName, argv: Array) -> Variant:
	var vargv := [self]
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

func applymR(key: StringName, argv: Array) -> Variant:
	var vargv := [self]
	vargv.append_array(argv)
	var value = null
	var data = define._props.get(key)
	if data is Callable:
		value = await data.callv(vargv)
	elif data is Array:
		for entry in data:
			value = await entry[1].callv(vargv)
	return value

func applymRS(key: StringName, argv: Array) -> Variant:
	var vargv := [self]
	vargv.append_array(argv)
	var handle = define._props.get(key)
	if handle != null: return await handle.callv(vargv)
	return null

func applymRSU(key: StringName, argv: Array) -> Variant:
	var vargv := [self]
	vargv.append_array(argv)
	return await define._props[key].callv(vargv)

## call lisper function methods
## [codeblock]
## R -> Raw:    only call on define
## S -> Single: not batch call stacks
## U -> Usafe:  fail when handle not found
## [/codeblock]
func applyv(key: StringName, ctx: LisperContext, argv: Array) -> Variant:
	var vargv := [self]
	vargv.append_array(argv)
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_fn(data, vargv)
	elif data is Array:
		for entry in data:
			value = await ctx.call_fn(entry[1], vargv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if Lisper.is_fn(data):
			value = await ctx.call_fn(data, vargv)
		elif data is Array:
			for entry in data:
				value = await ctx.call_fn(entry[1], vargv)
		lidx -= 1
	return value

func applyvS(key: StringName, ctx: LisperContext, argv: Array) -> Variant:
	var vargv := [self]
	vargv.append_array(argv)
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await ctx.call_fn(handle, vargv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await ctx.call_fn(handle, vargv)
		lidx -= 1
	return value

func applyvR(key: StringName, ctx: LisperContext, argv: Array) -> Variant:
	var vargv := [self]
	vargv.append_array(argv)
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_fn(data, vargv)
	elif data is Array:
		for entry in data:
			value = await ctx.call_fn(entry[1], vargv)
	return value

func applyvRS(key: StringName, ctx: LisperContext, argv: Array) -> Variant:
	var vargv := [self]
	vargv.append_array(argv)
	var handle = define._props.get(key)
	if handle != null: return await ctx.call_fn(handle, vargv)
	return null

func applyvRSU(key: StringName, ctx: LisperContext, argv: Array) -> Variant:
	var vargv := [self]
	vargv.append_array(argv)
	return await ctx.call_fn(define._props[key], vargv)

## call lisper raw function methods
## [codeblock]
## R -> Raw:    only call on define
## S -> Single: not batch call stacks
## U -> Usafe:  fail when handle not found
## [/codeblock]
func applyr(key: StringName, ctx: LisperContext, body: Array) -> Variant:
	var vargv := [Lisper.Raw(self)]
	vargv.append_array(body)
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_fn_raw(data, vargv)
	elif data is Array:
		for entry in data:
			value = await ctx.call_fn_raw(entry[1], vargv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		data = layers[lidx][1].get(key)
		if Lisper.is_fn(data):
			value = await ctx.call_fn_raw(data, vargv)
		elif data is Array:
			for entry in data:
				value = await ctx.call_fn_raw(entry[1], vargv)
		lidx -= 1
	return value

func applyrS(key: StringName, ctx: LisperContext, body: Array) -> Variant:
	var vargv := [Lisper.Raw(self)]
	vargv.append_array(body)
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = await ctx.call_fn_raw(handle, vargv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = await ctx.call_fn_raw(handle, vargv)
		lidx -= 1
	return value

func applyrR(key: StringName, ctx: LisperContext, body: Array) -> Variant:
	var vargv := [Lisper.Raw(self)]
	vargv.append_array(body)
	var value = null
	var data = define._props.get(key)
	if Lisper.is_fn(data):
		value = await ctx.call_fn_raw(data, vargv)
	elif data is Array:
		for entry in data:
			value = await ctx.call_fn_raw(entry[1], vargv)
	return value

func applyrRS(key: StringName, ctx: LisperContext, body: Array) -> Variant:
	var vargv := [Lisper.Raw(self)]
	vargv.append_array(body)
	var handle = define._props.get(key)
	if handle != null: return await ctx.call_fn_raw(handle, vargv)
	return null

func applyrRSU(key: StringName, ctx: LisperContext, body: Array) -> Variant:
	var vargv := [Lisper.Raw(self)]
	vargv.append_array(body)
	return await ctx.call_fn_raw(define._props[key], vargv)



func gsm(): return ['

defunc (do :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var act_name := await ctx.exec_as_keyword(body[1]) as StringName
			return await this.applyr(act_name, ctx, body.slice(2))
,')

defunc (callm :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var method := await ctx.exec_as_keyword(body[1]) as StringName
			var argv := await ctx.execs(body.slice(2)) as Array
			return await this.applym(method, argv)
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
			return null
,')

defunc (remove :const :gd ', func (this: Mono): this.remove() ,')
defunc (queue_remove :const :gd ', func (this: Mono): this.remove.call_deferred() ,')

']
