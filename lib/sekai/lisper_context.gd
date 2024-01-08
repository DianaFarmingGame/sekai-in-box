class_name LisperContext

var ENABLE_AGGRESSIVE_OPT := ProjectSettings.get_setting(&"global/enable_aggressive_opt", true) as bool

var parent = null
var vars := {}
var source = null

static func extend(ctx: LisperContext) -> LisperContext:
	var nctx := LisperContext.new()
	nctx.parent = ctx
	return nctx

func clone() -> LisperContext:
	var ctx := LisperContext.new()
	ctx.parent = parent
	ctx.vars = vars.duplicate(true)
	ctx.source = source
	return ctx

func fork() -> LisperContext:
	var ctx := LisperContext.new()
	ctx.parent = self
	return ctx

func get_var(name: StringName) -> Variant:
	var res = vars.get(name)
	return res[1] if res != null else parent.get_var(name) if parent != null else null

func set_var(name: StringName, data: Variant) -> void:
	var pdata = vars.get(name)
	if pdata != null:
		vars[name][1] = data
	else:
		parent.set_var(name, data) if parent != null else null

func def_var(flags: Array[Lisper.VarFlag], name: StringName, data: Variant) -> void:
	vars[name] = [flags, data]

func def_const(name: StringName, data: Variant) -> void:
	vars[name] = [[Lisper.VarFlag.CONST], data]

func def_vars(flags: Array[Lisper.VarFlag], data_map: Dictionary) -> void:
	for k in data_map.keys():
		vars[k] = [flags, data_map[k]]

func def_consts(data_map: Dictionary) -> void:
	for k in data_map.keys():
		vars[k] = [[Lisper.VarFlag.CONST], data_map[k]]

func def_fn(flags: Array[Lisper.VarFlag], type: Lisper.FnType, name: StringName, handle: Variant) -> void:
	vars[name] = [flags, [type, handle]]

func def_fns(flags: Array[Lisper.VarFlag], type: Lisper.FnType, handle_map: Dictionary) -> void:
	for k in handle_map.keys():
		vars[k] = [flags, [type, handle_map[k]]]

func is_const(name: StringName) -> bool:
	var res = vars.get(name)
	return res[0].has(Lisper.VarFlag.CONST) if res != null else parent.is_const(name) if parent != null else null

func get_source() -> Variant:
	return source if source != null else parent.get_source() if parent != null else null

func log_error(node: Array, msg) -> void:
	var src = get_source()
	if src != null and node.size() > 2:
		var offset := node[2] as Array
		var pre_src := (src as String).substr(offset[0], offset[1] - offset[0])
		var lines := pre_src.split('\n')
		var slnum := (src as String).count('\n', 0, offset[0]) if offset[0] > 0 else 0
		for i in lines.size():
			lines[i] = String.num_uint64(i + slnum + 1).lpad(4) + "|\t" + lines[i]
		printerr(msg, "\n", '\n'.join(lines))
	else:
		printerr(msg, " @:")
		printerr(Lisper.stringify(node))
	print('')

func exec_as_keyword(node: Array) -> Variant:
	match node[0]:
		Lisper.TType.RAW, Lisper.TType.TOKEN, Lisper.TType.KEYWORD:
			return node[1]
		Lisper.TType.STRING:
			return StringName(node[1])
	log_error(node, str("unable to convert node to keyword: ", node))
	return null

func exec_as_string(node: Array) -> Variant:
	var value = node[1]
	if value is String: return value
	else: return String(value)

func eval(expr: String) -> Variant:
	var tokens = Lisper.tokenize(expr)
	source = expr
	if tokens != null:
		var res = await execs(tokens)
		source = null
		return res
	else:
		push_error("failed to tokenize expression")
		printerr("failed to tokenize expression:")
		printerr(source)
		return null

func execs(nodes: Array) -> Array:
	var res := []
	res.resize(nodes.size())
	for idx in nodes.size():
		res[idx] = await exec(nodes[idx])
	return res

func exec(node: Array) -> Variant:
	match node[0]:
		Lisper.TType.RAW, Lisper.TType.NUMBER, Lisper.TType.BOOL, Lisper.TType.KEYWORD, Lisper.TType.STRING:
			return node[1]
		Lisper.TType.TOKEN:
			return get_var(node[1])
		Lisper.TType.LIST:
			var head = node[1][0]
			var body = (node[1] as Array).slice(1)
			var handle = await exec(head)
			if handle is Array:
				return await call_rawfn(handle, body)
			elif handle == null:
				log_error(node, str("call handle not found: ", head))
			else:
				log_error(node, str("unexpected call handle: ", handle))
			return null
		Lisper.TType.ARRAY:
			return await execs(node[1])
		Lisper.TType.MAP:
			return await exec_map_part(node[1])
	log_error(node, str("unknown node: ", node))
	return null

@warning_ignore("integer_division")
func exec_map_part(pairs: Array) -> Dictionary:
	var res := {}
	for i in pairs.size() / 2:
		var k = exec_as_keyword(pairs[2 * i])
		var v = await exec(pairs[2 * i + 1])
		res[k] = v
	return res

func call_rawfn(handle: Array, body: Array) -> Variant:
	match handle[0]:
		Lisper.FnType.GD_RAW:
			return await handle[1].call(self, body, false)
		Lisper.FnType.GD_MACRO:
			return await exec(await handle[1].call(self, body))
		Lisper.FnType.GD_CALL, Lisper.FnType.GD_CALL_PURE:
			var vargs := await execs(body)
			return await handle[1].callv(vargs)
		Lisper.FnType.GD_APPLY, Lisper.FnType.GD_APPLY_PURE:
			var vargs := await execs(body)
			return await handle[1].call(self, vargs)
		Lisper.FnType.LP_CALL:
			var fctx := fork()
			var args := handle[1] as Array
			if args.size() != body.size():
				push_error("argument list not match expect ", args.size(), " found ", body.size())
				printerr("argument list not match expect ", args.size(), " found ", body.size())
				printerr("need: ", args)
				printerr("provide: ", Lisper.stringifys(body))
				return null
			var vargs := await execs(body)
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			return (await fctx.execs(handle[2]))[-1]
		_:
			push_error("unknown call handle type: ", handle)
			printerr("unknown call handle type: ", handle)
			printerr("arguments: ", Lisper.stringifys(body))
			return null

func call_fn(handle: Array, vargs: Array) -> Variant:
	match handle[0]:
		Lisper.FnType.GD_RAW:
			return await handle[1].call(self, vargs.map(Lisper.Raw), false)
		Lisper.FnType.GD_MACRO:
			return await exec(await handle[1].call(self, vargs.map(Lisper.Raw)))
		Lisper.FnType.GD_CALL, Lisper.FnType.GD_CALL_PURE:
			return await handle[1].callv(vargs)
		Lisper.FnType.GD_APPLY, Lisper.FnType.GD_APPLY_PURE:
			return await handle[1].call(self, vargs)
		Lisper.FnType.LP_CALL:
			var fctx := fork()
			var args := handle[1] as Array
			if args.size() != vargs.size():
				push_error("argument list not match expect ", args.size(), " found ", vargs.size())
				printerr("argument list not match expect ", args.size(), " found ", vargs.size())
				printerr("need: ", args)
				printerr("provide: ", vargs)
				return null
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			return (await fctx.execs(handle[2]))[-1]
		_:
			push_error("unknown call handle type: ", handle)
			printerr("unknown call handle type: ", handle)
			printerr("arguments: ", vargs)
			return null

func call_anyway(handle: Variant, vargs: Array) -> Variant:
	if handle is Callable:
		return await handle.callv(vargs)
	if handle is Array:
		return await call_fn(handle, vargs)
	push_error("unknown call handle type: ", handle)
	printerr("unknown call handle type: ", handle)
	printerr("arguments: ", vargs)
	return null

var _flag_comptime := false
var _flag_pure_rollback := false

func check_valid_handle(handle: Array) -> bool:
	if _flag_comptime:
		match handle[0]:
			Lisper.FnType.GD_CALL_PURE, Lisper.FnType.GD_APPLY_PURE:
				return true
		_flag_pure_rollback = true
		return false
	else:
		return true

func compile(node: Array) -> Array:
	var eao := ENABLE_AGGRESSIVE_OPT
	match node[0]:
		Lisper.TType.TOKEN:
			var vname := exec_as_keyword(node) as StringName
			if is_const(vname):
				return Lisper.Raw(await exec(node))
			return node
		Lisper.TType.NUMBER, Lisper.TType.BOOL, Lisper.TType.KEYWORD, Lisper.TType.STRING:
			return Lisper.Raw(node[1]) if eao else node
		Lisper.TType.LIST:
			var head := node[1][0] as Array
			var body := node[1].slice(1) as Array
			head = await compile(head)
			if head[0] == Lisper.TType.RAW:
				var handle := head[1] as Array
				if handle[0] == Lisper.FnType.GD_RAW:
					_flag_comptime = true
					var res := await handle[1].call(self, body, true) as Array
					_flag_comptime = false
					if Lisper.is_raw_override(res):
						return await compile(res)
					body = await compiles(res)
					var cdata := [head]
					cdata.append_array(body)
					return Lisper.List(cdata)
				if eao:
					match handle[0]:
						Lisper.FnType.GD_MACRO:
							var cdata := [head]
							cdata.append_array(body)
							_flag_comptime = true
							var res = await handle[1].call(self, body)
							_flag_comptime = false
							return await compile(res)
						Lisper.FnType.GD_CALL_PURE, Lisper.FnType.GD_APPLY_PURE:
							body = await compiles(body)
							if body.all(Lisper.is_raw):
								var cdata := [head]
								cdata.append_array(body)
								_flag_comptime = true
								_flag_pure_rollback = false
								var res = await exec(Lisper.List(cdata))
								_flag_comptime = false
								if _flag_pure_rollback:
									return Lisper.List(cdata)
								else:
									return Lisper.Raw(res)
			var cdata := [head]
			body = await compiles(body)
			cdata.append_array(body)
			return Lisper.List(cdata)
		Lisper.TType.ARRAY:
			var body := node[1] as Array
			body = await compiles(body)
			if body.all(Lisper.is_raw) and eao:
				return Lisper.Raw(body.map(func (n): return n[1]))
			else:
				return Lisper.Array(body)
		Lisper.TType.MAP:
			var pairs := node[1] as Array
			var cdata := []
			var is_pure := true
			cdata.resize(pairs.size())
			for i in pairs.size() / 2:
				cdata[2 * i] = Lisper.Raw(exec_as_keyword(pairs[2 * i]))
				var v := await compile(pairs[2 * i + 1])
				if not Lisper.is_raw(v[0]): is_pure = false
				cdata[2 * i + 1] = v
			if is_pure and eao:
				var res := {}
				for i in cdata.size() / 2:
					var k = cdata[2 * i][1]
					var v = cdata[2 * i + 1][1]
					res[k] = v
				return Lisper.Raw(res)
			else:
				return [Lisper.TType.MAP, cdata]
		Lisper.TType.RAW:
			return node
	log_error(node, str("unknown node: ", node))
	return node

func compiles(body: Array) -> Array:
	return await Async.array_map(body, func (n): return await compile(n))
