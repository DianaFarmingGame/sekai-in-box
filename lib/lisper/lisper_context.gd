class_name LisperContext

static var ENABLE_AGGRESSIVE_OPT := ProjectSettings.get_setting(&"sekai/enable_aggressive_opt", true) as bool
static var ENABLE_STRINGIFY_REVERSE_TRACE := true

var parent = null
var vars := {}
var source = null
var print_head := ""
var jumps := []

static func extend(ctx: LisperContext) -> LisperContext:
	var nctx := LisperContext.new()
	nctx.parent = ctx
	nctx.print_head = ctx.print_head
	return nctx

static var _root_idx := 0

static func make(pname = null) -> LisperContext:
	if pname == null: pname = str("root::", _root_idx)
	var ctx := LisperContext.new()
	LisperDebugger.sign_context(pname, ctx)
	_root_idx += 1
	return ctx

func clone() -> LisperContext:
	var ctx := LisperContext.new()
	ctx.parent = parent
	ctx.vars = vars.duplicate(true)
	ctx.source = source
	ctx.print_head = print_head
	return ctx

func fork() -> LisperContext:
	var ctx := LisperContext.new()
	ctx.parent = self
	ctx.print_head = print_head
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

func find_var(value: Variant) -> Variant:
	var res = null
	for k in vars:
		if is_same(value, vars[k][1]):
			res = k
			break
	return res if res != null else parent.find_var(value) if parent != null else null

func is_const(name: StringName) -> Variant:
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
		printerr(stringify(node))
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
			if handle is Callable or handle is Array:
				jumps.push_back(node)
				var res = await call_fn_raw(handle, body)
				jumps.pop_back()
				return res
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

func exec_map_part(pairs: Array) -> Dictionary:
	var res := {}
	for i in pairs.size() / 2:
		var k = exec_as_keyword(pairs[2 * i])
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
				push_error("argument list not match expect ", args.size(), " found ", body.size())
				printerr("argument list not match expect ", args.size(), " found ", body.size())
				printerr("need: ", args)
				printerr("provide: ", stringifys(body))
				return null
			var vargs := await execs(body)
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			return (await fctx.execs(Lisper.fn_lp_get_body(handle)))[-1]
		_:
			push_error("unknown call handle type: ", handle)
			printerr("unknown call handle type: ", handle)
			printerr("arguments: ", stringifys(body))
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
				push_error("argument list not match expect ", args.size(), " found ", vargs.size())
				printerr("argument list not match expect ", args.size(), " found ", vargs.size())
				printerr("need: ", args)
				printerr("provide: ", vargs)
				return null
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			return (await fctx.execs(Lisper.fn_lp_get_body(handle)))[-1]
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
				cdata[2 * i] = Lisper.Raw(exec_as_keyword(pairs[2 * i]))
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
	log_error(node, str("unknown node: ", node))
	return node

func compiles(body: Array) -> Array:
	return await Async.array_map(body, func (n): return await compile(n))

func stringify_raw(data: Variant, indent := 0, enable_rev_trace := ENABLE_STRINGIFY_REVERSE_TRACE) -> String:
	if enable_rev_trace and (data is Callable or data is Array or data is Dictionary):
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
				indent += msg.length() + 2
				msg += " ([" + ' '.join(Lisper.fn_lp_get_args(data)) + "]\n" + ''.lpad(indent) + stringifys(Lisper.fn_lp_get_body(data), indent) + ')'
		return msg
	if data is Dictionary:
		var res := ['{']
		for k in data.keys():
			var v = data[k]
			res.append('\n' + ''.lpad(indent + 2, ' ') + k + ' ' + stringify_raw(v, indent + 2))
		res.append('\n' + ''.lpad(indent, ' ') + '}')
		return ''.join(res)
	if data is Array:
		var res := '[' + (stringify_raw(data[0], indent + 1) if data.size() > 0 else '')
		for n in data.slice(1):
			var idn := Lisper.count_last_len(res, indent)
			if idn > 8:
				res += '\n' + ''.lpad(indent, ' ') + ' ' + stringify_raw(n, indent + 1)
			else:
				res += ' ' + stringify_raw(n, idn + 1)
		res += ']'
		return res
	if data is String:
		var slices := (data as String).split('\n')
		return '"' + slices[0] + ''.join(Array(slices.slice(1)).map(func (s): return '\n' + ''.lpad(indent + 1, ' ') + s)) + '"'
	if data is StringName:
		var slices := String(data).split('\n')
		return '&' + slices[0] + ''.join(Array(slices.slice(1)).map(func (s): return '\n' + ''.lpad(indent + 1, ' ') + s))
	if data is bool:
		return "#t" if data else "#f"
	return var_to_str(data)

func stringify(node: Array, indent := 0) -> String:
	match node[0]:
		Lisper.TType.TOKEN:
			return str(node[1])
		Lisper.TType.NUMBER:
			return str(node[1])
		Lisper.TType.BOOL:
			return "#t" if node[1] else "#f"
		Lisper.TType.KEYWORD:
			return str('&', node[1])
		Lisper.TType.STRING:
			var slices := (node[1] as String).split('\n')
			return '"' + slices[0] + ''.join(Array(slices.slice(1)).map(func (s): return '\n' + ''.lpad(indent + 1, ' ') + s)) + '"'
		Lisper.TType.LIST:
			var head_str := stringify(node[1][0], indent)
			indent = Lisper.count_last_len(head_str, indent) + 2
			var body := node[1].slice(1) as Array
			if body.size() <= 1:
				return head_str + ' (' + ' '.join(body.map(func (n): return stringify(n, indent))) + ')'
			return head_str + ' (' + \
			stringify(body[0], indent) + \
			''.join(body.slice(1).map(func (n): return '\n' + ''.lpad(indent, ' ') + stringify(n, indent))) + ')'
		Lisper.TType.ARRAY:
			var res := '[' + (stringify(node[1][0], indent + 1) if node[1].size() > 0 else '')
			for n in node[1].slice(1):
				var idn := Lisper.count_last_len(res, indent)
				if idn > 8:
					res += '\n' + ''.lpad(indent, ' ') + ' ' + stringify(n, indent + 1)
				else:
					res += ' ' + stringify(n, idn + 1)
			res += ']'
			return res
		Lisper.TType.MAP:
			var res := ['{']
			var key := true
			var idn := indent
			for n in node[1]:
				if key:
					var vstr := '\n' + ''.lpad(indent + 2, ' ') + stringify(n, indent + 2)
					idn = Lisper.count_last_len(vstr, indent) + 1
					res.append(vstr)
				else:
					res.append(' ' + stringify(n, idn))
				key = not key
			res.append('\n' + ''.lpad(indent, ' ') + '}')
			return ''.join(res)
		Lisper.TType.RAW:
			var value = node[1]
			return '<' + stringify_raw(value, indent + 1) + '>'
	push_error("unknown typed node: ", node)
	return "<unknown>"

func stringifys(body: Array, indent := 0) -> String:
	return ' '.join(body.map(func (n): return stringify(n, indent)))

func strip_flags(body: Array) -> Array:
	var nbody := []
	var flags := []
	for n in body:
		if n[0] == Lisper.TType.TOKEN and (n[1] as StringName).begins_with(':'):
			flags.append(n[1])
		else:
			nbody.append(n)
	return [flags, nbody]