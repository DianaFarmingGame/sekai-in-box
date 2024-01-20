class_name LisperContext

static var ENABLE_AGGRESSIVE_OPT := ProjectSettings.get_setting(&"sekai/enable_aggressive_opt", true) as bool
static var ENABLE_STRINGIFY_REVERSE_TRACE := true

var parent = null
var vars := {}
var remembers := []
var source = null
var print_head := ""
var dbg_name := ""
var jumps := []
var sealed := false

static func extend(ctx: LisperContext) -> LisperContext:
	var nctx := LisperContext.new()
	nctx.parent = ctx
	nctx.print_head = ctx.print_head
	return nctx

static var _root_idx := 0

static func make(pname = null) -> LisperContext:
	if pname == null: pname = str("root::", _root_idx)
	var ctx := LisperContext.new()
	ctx.dbg_name = pname
	LisperDebugger.sign_context(ctx.dbg_name, ctx)
	_root_idx += 1
	return ctx

func clone() -> LisperContext:
	var ctx := LisperContext.new()
	ctx.parent = parent
	ctx.vars = vars.duplicate(true)
	ctx.remembers = remembers.duplicate()
	ctx.source = source
	ctx.print_head = print_head
	return ctx

func fork() -> LisperContext:
	var ctx := LisperContext.new()
	ctx.parent = self
	ctx.print_head = print_head
	return ctx

func destroy() -> void:
	LisperDebugger.unsign_context(dbg_name, self)

func seal() -> void:
	sealed = true

func unseal() -> void:
	sealed = false

func get_var(name: StringName) -> Variant:
	var res = vars.get(name)
	return res[1] if res != null else parent.get_var(name) if parent != null else null

func set_var(name: StringName, data: Variant) -> void:
	if sealed:
		push_error("error modify sealed context")
		printerr("error modify sealed context:")
		printerr("set ", name, ": ", data)
	var pdata = vars.get(name)
	if pdata != null:
		vars[name][1] = data
	else:
		parent.set_var(name, data) if parent != null else null

func def_var(flags: Array, name: StringName, data: Variant) -> void:
	if sealed:
		push_error("error modify sealed context")
		printerr("error modify sealed context:")
		printerr("def ", name, ": ", data)
	vars[name] = [flags, data]

func undef_var(name: StringName) -> void:
	if sealed:
		push_error("error modify sealed context")
		printerr("error modify sealed context:")
		printerr("undef ", name)
	vars.erase(name)

func def_const(name: StringName, data: Variant) -> void:
	if sealed:
		push_error("error modify sealed context")
		printerr("error modify sealed context:")
		printerr("def ", name, ": ", data)
	vars[name] = [[Lisper.VarFlag.CONST], data]

var _module_meta_stack := []

func push_module_meta(meta: Dictionary) -> void:
	var pmeta := {}
	for k in meta.keys():
		pmeta[k] = vars.get(k)
		vars[k] = [[Lisper.VarFlag.CONST], meta[k]]
	_module_meta_stack.push_back(pmeta)

func pop_module_meta() -> void:
	if _module_meta_stack.size() > 0:
		var pmeta := _module_meta_stack.pop_back() as Dictionary
		vars.merge(pmeta, true)
		for k in pmeta.keys():
			if pmeta[k] != null:
				vars[k] = pmeta[k]
			else:
				vars.erase(k)

func def_vars(flags: Array, data_map: Dictionary) -> void:
	if sealed:
		push_error("error modify sealed context")
		printerr("error modify sealed context:")
		printerr("def ", data_map)
	for k in data_map.keys():
		vars[k] = [flags, data_map[k]]

func def_consts(data_map: Dictionary) -> void:
	if sealed:
		push_error("error modify sealed context")
		printerr("error modify sealed context:")
		printerr("def ", data_map)
	for k in data_map.keys():
		vars[k] = [[Lisper.VarFlag.CONST], data_map[k]]

func def_fn(flags: Array, type: Lisper.FnType, name: StringName, handle: Variant) -> void:
	if sealed:
		push_error("error modify sealed context")
		printerr("error modify sealed context:")
		printerr("defunc ", name, handle)
	vars[name] = [flags, [type, handle]]

func def_fns(flags: Array, type: Lisper.FnType, handle_map: Dictionary) -> void:
	if sealed:
		push_error("error modify sealed context")
		printerr("error modify sealed context:")
		printerr("defunc ", handle_map)
	for k in handle_map.keys():
		vars[k] = [flags, [type, handle_map[k]]]

func find_var(value: Variant) -> Variant:
	for k in vars:
		if is_same(value, vars[k][1]):
			return k
	return parent.find_var(value) if parent != null else null

func is_const(name: StringName) -> Variant:
	var res = vars.get(name)
	return res[0].has(Lisper.VarFlag.CONST) if res != null else parent.is_const(name) if parent != null else null

func get_source() -> Variant:
	return source if source != null else parent.get_source() if parent != null else null

func log_error(node: Array, msg) -> void:
	await error(msg + " @:\n" + stringify(node))

func exec_as_keyword(node: Array) -> Variant:
	match node[0]:
		Lisper.TType.RAW, Lisper.TType.TOKEN, Lisper.TType.KEYWORD:
			return node[1]
		Lisper.TType.STRING:
			return StringName(node[1])
	await log_error(node, str("unable to convert node to keyword: ", node))
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

func meval(content: Array) -> Variant:
	var gss_parts := []
	var inserts := []
	var is_gss := true
	for part in content:
		if is_gss:
			gss_parts.append(part)
		else:
			gss_parts.append(str(":gsm-insert-", inserts.size()))
			inserts.append(part)
		is_gss = not is_gss
	var gss := ' '.join(gss_parts)
	var gss_data = Lisper.tokenize(gss)
	if gss_data != null:
		gss_data = gss_data.map(func (n): return _gsm_replace(inserts, n))
		return await execs(gss_data)
	push_error("failed to tokenize expression")
	printerr("failed to tokenize expression:")
	printerr(gss)
	return null

func _gsm_replace(inserts: Array, node: Array) -> Array:
	match node[0]:
		Lisper.TType.LIST, Lisper.TType.ARRAY, Lisper.TType.MAP:
			var body := (node[1] as Array).map(func (n): return _gsm_replace(inserts, n))
			return [node[0], body]
		Lisper.TType.TOKEN:
			if node[1].begins_with(":gsm-insert-"):
				var idx := int(node[1].rsplit('-', true, 1)[1])
				return Lisper.Raw(inserts[idx])
	return node

func execs(nodes: Array) -> Array:
	jumps.push_back(Lisper.apply(&":flow", [nodes]))
	var res := []
	res.resize(nodes.size())
	for idx in nodes.size():
		res[idx] = await exec(nodes[idx])
	jumps.pop_back()
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
			jumps.push_back(node)
			var handle = await exec(head)
			if Lisper.is_fn(handle):
				var res = await call_fn_raw(handle, body)
				jumps.pop_back()
				return res
			elif handle == null:
				await log_error(node, str("call handle not found: ", head))
			else:
				await log_error(node, str("unexpected call handle: ", handle))
			jumps.pop_back()
			return null
		Lisper.TType.ARRAY:
			return await execs(node[1])
		Lisper.TType.MAP:
			return await exec_map_part(node[1])
	await log_error(node, str("unknown node: ", node))
	return null

func exec_map_part(pairs: Array) -> Dictionary:
	var res := {}
	for i in pairs.size() / 2:
		var k = await exec_as_keyword(pairs[2 * i])
		var v = await exec(pairs[2 * i + 1])
		res[k] = v
	return res

func call_fn_raw(handle: Variant, body: Array) -> Variant:
	match Lisper.fn_get_type(handle):
		Lisper.FnType.GD_RAW:
			return await Lisper.fn_gd_get_handle(handle).call(self, body, false)
		Lisper.FnType.GD_MACRO:
			return await exec(await Lisper.fn_gd_get_handle(handle).call(self, body))
		Lisper.FnType.GD_CALL, Lisper.FnType.GD_CALL_PURE:
			var vargs := await execs(body)
			return await Lisper.fn_gd_get_handle(handle).callv(vargs)
		Lisper.FnType.GD_APPLY, Lisper.FnType.GD_APPLY_PURE:
			var vargs := await execs(body)
			return await Lisper.fn_gd_get_handle(handle).call(self, vargs)
		Lisper.FnType.LP_CALL, Lisper.FnType.LP_CALL_PURE:
			var fctx := fork()
			var args := Lisper.fn_lp_get_args(handle)
			if args.size() != body.size():
				await error(str("argument list not match expect ", args.size(), " found ", body.size(), '\n',
					"need: ", args, '\n',
					"provide: ", stringifys(body),
				))
				return null
			var vargs := await execs(body)
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			return (await fctx.execs(Lisper.fn_lp_get_body(handle)))[-1]
		_:
			await error(str("unknown call handle type: ", handle, '\n',
				"arguments: ", stringifys(body),
			))
			return null

func call_fn(handle: Variant, vargs: Array) -> Variant:
	match Lisper.fn_get_type(handle):
		Lisper.FnType.GD_RAW:
			return await Lisper.fn_gd_get_handle(handle).call(self, vargs.map(Lisper.Raw), false)
		Lisper.FnType.GD_MACRO:
			return await exec(await Lisper.fn_gd_get_handle(handle).call(self, vargs.map(Lisper.Raw)))
		Lisper.FnType.GD_CALL, Lisper.FnType.GD_CALL_PURE:
			return await Lisper.fn_gd_get_handle(handle).callv(vargs)
		Lisper.FnType.GD_APPLY, Lisper.FnType.GD_APPLY_PURE:
			return await Lisper.fn_gd_get_handle(handle).call(self, vargs)
		Lisper.FnType.LP_CALL, Lisper.FnType.LP_CALL_PURE:
			var fctx := fork()
			var args := Lisper.fn_lp_get_args(handle)
			if args.size() != vargs.size():
				await error(str("argument list not match expect ", args.size(), " found ", vargs.size(), '\n',
					"need: ", args, '\n',
					"provide: ", stringify_raws(vargs),
				))
				return null
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			return (await fctx.execs(Lisper.fn_lp_get_body(handle)))[-1]
		_:
			await error(str("unknown call handle type: ", handle, '\n',
				"arguments: ", stringify_raws(vargs),
			))
			return null

var _flag_comptime := false
var _flag_pure_rollback := false

func check_valid_handle(handle: Variant) -> bool:
	if _flag_comptime:
		match Lisper.fn_get_type(handle):
			Lisper.FnType.GD_CALL_PURE, \
			Lisper.FnType.GD_APPLY_PURE, \
			Lisper.FnType.LP_CALL_PURE:
				return true
		_flag_pure_rollback = true
		return false
	else:
		return true

func compile(node: Array) -> Array:
	var eao := LisperContext.ENABLE_AGGRESSIVE_OPT
	match node[0]:
		Lisper.TType.TOKEN:
			var vname := await exec_as_keyword(node) as StringName
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
				var handle = head[1]
				if Lisper.fn_get_type(handle) == Lisper.FnType.GD_RAW:
					_flag_comptime = true
					var res := await Lisper.fn_gd_get_handle(handle).call(self, body, true) as Array
					_flag_comptime = false
					if Lisper.is_raw_override(res):
						return await compile(res[1])
					var cdata := [head]
					cdata.append_array(res)
					return Lisper.List(cdata)
				if eao:
					match Lisper.fn_get_type(handle):
						Lisper.FnType.GD_MACRO:
							var cdata := [head]
							cdata.append_array(body)
							_flag_comptime = true
							var res = await Lisper.fn_gd_get_handle(handle).call(self, body)
							_flag_comptime = false
							return await compile(res)
						Lisper.FnType.GD_CALL_PURE, \
						Lisper.FnType.GD_APPLY_PURE, \
						Lisper.FnType.LP_CALL_PURE:
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
				cdata[2 * i] = Lisper.Raw(await exec_as_keyword(pairs[2 * i]))
				var v := await compile(pairs[2 * i + 1])
				if not Lisper.is_raw(v): is_pure = false
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
	await log_error(node, str("unknown node: ", node))
	return node

func compiles(body: Array) -> Array:
	return await Async.array_map(body, func (n): return await compile(n))

const STRINGIFY_MAX_DEPTH := 32

func stringify_raw_prop_dict(data: Dictionary, indent := 0, depth := 0) -> String:
	if depth > STRINGIFY_MAX_DEPTH: return "..."
	if data.size() == 0: return ""
	var tags := []
	indent += 2
	for k in data.keys():
		tags.append('\n' + ''.lpad(indent) + k + ': ')
		var value = data[k]
		if value is Dictionary:
			tags.append(stringify_raw_prop_dict(value, indent, depth + 1))
		else:
			tags.append(stringify_raw(data[k], indent + k.length() + 2, depth + 1))
	return ''.join(tags)

func stringify_raw(data: Variant, indent := 0, depth := 0, enable_rev_trace := ENABLE_STRINGIFY_REVERSE_TRACE) -> String:
	if depth > STRINGIFY_MAX_DEPTH: return "..."
	if enable_rev_trace and (data is Array or data is Dictionary or Lisper.is_fn(data) or data is Mono):
		var vname = find_var(data)
		if vname != null:
			return '#' + vname
	if data is float:
		return str(floori(data)) if is_zero_approx(fmod(data, 1)) else str(data)
	if Lisper.is_fn(data):
		var type = Lisper.FnType.find_key(Lisper.fn_get_type(data))
		var msg := 'λ:' + type as String
		match Lisper.fn_get_type(data):
			Lisper.FnType.LP_CALL, Lisper.FnType.LP_CALL_PURE:
				var tags := [" [" + ' '.join(Lisper.fn_lp_get_args(data)) + "]: "]
				indent += 2
				for node in Lisper.fn_lp_get_body(data):
					tags.append('\n' + ''.lpad(indent) + stringify(node, indent, depth + 8))
				msg += ''.join(tags)
		return msg
	if data is Dictionary:
		if data.size() == 0: return "{}"
		var tags := ['{']
		indent += 2
		for k in data.keys():
			tags.append('\n' + ''.lpad(indent) + k + ': ')
			var value = data[k]
			if value is Dictionary:
				tags.append(stringify_raw_prop_dict(value, indent, depth + 1))
			else:
				tags.append(stringify_raw(data[k], indent + k.length() + 2, depth + 1))
		tags.append('\n' + ''.lpad(indent - 2) + '}')
		return ''.join(tags)
	if data is Array:
		var res := '['
		var strip_first := true
		var body := data as Array
		for n in body:
			if strip_first:
				strip_first = false
				res += stringify_raw(n, indent + 1, depth + 1)
			else:
				var idn := Lisper.count_last_len(res, indent)
				if idn - indent > 8:
					res += ('\n' + ''.lpad(indent) + ' ') + stringify_raw(n, indent + 1, depth + 1)
				else:
					res += ' ' + stringify_raw(n, idn + 1, depth + 1)
		res += ']'
		return res
	if data is String:
		var slices := (data as String).split('\n')
		return '"' + slices[0] + ''.join(Array(slices.slice(1)).map(func (s): return '\n' + ''.lpad(indent + 1) + s)) + '"'
	if data is StringName:
		var slices := String(data).split('\n')
		return '&' + slices[0] + ''.join(Array(slices.slice(1)).map(func (s): return '\n' + ''.lpad(indent + 1) + s))
	if data is bool:
		return "#t" if data else "#f"
	if data is Object:
		if data is Mono:
			var ref := str('@', data.define.id if data.define.id != &"" else data.define.ref)
			if enable_rev_trace:
				return "#Mono" + ref
			else:
				if data.layers.size() == 0: return "#Mono" + ref + " {}"
				var tags := ["#Mono" + ref + ': ']
				indent += 2
				for l in data.layers:
					tags.append('\n' + ''.lpad(indent) + l[0] + ': ')
					tags.append(stringify_raw_prop_dict(l[1], indent, depth + 1))
				return ''.join(tags)
		return "#GDObject"
	return var_to_str(data)

func stringify_raws(data_ary: Array, indent := 0, depth := 0, enable_rev_trace := ENABLE_STRINGIFY_REVERSE_TRACE) -> String:
	return ' '.join(data_ary.map(func (n): return stringify_raw(n, indent, depth, enable_rev_trace)))

func stringify_rich(node: Array, indent := 0, depth := 0) -> Array:
	if depth > STRINGIFY_MAX_DEPTH: return [node, "..."]
	match node[0]:
		Lisper.TType.TOKEN:
			return [node, str(node[1])]
		Lisper.TType.NUMBER:
			return [node, str(node[1])]
		Lisper.TType.BOOL:
			return [node, "#t" if node[1] else "#f"]
		Lisper.TType.KEYWORD:
			return [node, str('&', node[1])]
		Lisper.TType.STRING:
			var slices := (node[1] as String).split('\n')
			var res := '"' + slices[0] + ''.join(Array(slices.slice(1)).map(func (s): return '\n' + ''.lpad(indent + 1) + s)) + '"'
			return [node, res]
		Lisper.TType.LIST:
			var head := stringify_rich(node[1][0], indent, depth + 1)
			var head_str := Lisper.stringify_flatten(head)
			var tags := [node, head, ' (']
			indent = Lisper.count_last_len(head_str, indent) + 2
			var body := node[1].slice(1) as Array
			var strip_first := true
			for n in body:
				if strip_first: strip_first = false
				else:
					tags.append('\n' + ''.lpad(indent))
				tags.append(stringify_rich(n, indent, depth + 1))
			tags.append(')')
			return tags
		Lisper.TType.ARRAY:
			var res := '['
			var tags := [node, '[']
			var strip_first := true
			var body := node[1] as Array
			for n in body:
				if strip_first:
					strip_first = false
					var t := stringify_rich(n, indent + 1, depth + 1)
					res += Lisper.stringify_flatten(t)
					tags.append(t)
				else:
					var idn := Lisper.count_last_len(res, indent)
					if idn - indent > 8:
						tags.append('\n' + ''.lpad(indent) + ' ')
						var t := stringify_rich(n, indent + 1, depth + 1)
						res += tags[-1] + Lisper.stringify_flatten(t)
						tags.append(t)
					else:
						tags.append(' ')
						var t := stringify_rich(n, idn + 1, depth + 1)
						res += tags[-1] + Lisper.stringify_flatten(t)
						tags.append(t)
			tags.append(']')
			return tags
		Lisper.TType.MAP:
			if node[1].size() == 0: return [node, "{}"]
			var tags := [node, '{']
			var key := true
			var idn := indent
			for n in node[1]:
				if key:
					var t := stringify_rich(n, indent + 2, depth + 1)
					tags.append('\n' + ''.lpad(indent + 2))
					var vstr := tags[-1] + Lisper.stringify_flatten(t) as String
					tags.append(t)
					idn = Lisper.count_last_len(vstr, indent) + 1
				else:
					tags.append(' ')
					tags.append(stringify_rich(n, idn, depth + 1))
				key = not key
			tags.append('\n' + ''.lpad(indent) + '}')
			return tags
		Lisper.TType.RAW:
			var value = node[1]
			return [node, '<' + stringify_raw(value, indent + 1, depth + 8) + '>']
	push_error("unknown typed node: ", node)
	return [node, "<unknown>"]

func stringify(node: Array, indent := 0, depth := 0) -> String:
	return Lisper.stringify_flatten(stringify_rich(node, indent, depth))

func stringifys(body: Array, indent := 0, depth := 0) -> String:
	return ' '.join(body.map(func (n): return stringify(n, indent, depth)))

func strip_flags(body: Array) -> Array:
	var nbody := []
	var flags := []
	for n in body:
		if n[0] == Lisper.TType.TOKEN and (n[1] as StringName).begins_with(':'):
			flags.append(n[1])
		else:
			nbody.append(n)
	return [flags, nbody]

func test(cond: bool, info := "<test>") -> void:
	@warning_ignore("assert_always_true")
	assert(true, await _test(cond, info))
	pass

func _test(cond: bool, info: String) -> String:
	if not cond:
		info = "test failed in: " + info
		push_error("[lisper] " + info)
		printerr("[lisper] " + info)
		LisperDebugger.output(info, 0xff660044, " ⚠ : ", "     ")
		await trigger_break("!::test")
	return info

func error(info := "<error>") -> void:
	@warning_ignore("assert_always_true")
	assert(true, await _error(info))
	pass

func _error(info: String) -> String:
	info = "error: " + info
	push_error("[lisper] " + info)
	printerr("[lisper] " + info)
	LisperDebugger.output(info, 0xff660044, "   ⚠ ", "     ")
	await trigger_break("!::error")
	return info

func trigger_break(vname := "!::break") -> void:
	LisperDebugger.sign_context(vname, self)
	LisperDebugger.break_waiting = true
	LisperDebugger.grab_focus()
	print_rich("[color=green][lisper] interrupted by debugger[/color]")
	await LisperDebugger.break_passed
	LisperDebugger.break_waiting = false
	LisperDebugger.unsign_context(vname, self)
