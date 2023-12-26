class_name LisperContext
var parent = null
var vars := {}
var source = null

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

func def_vars(flags: Array[Lisper.VarFlag], data_map: Dictionary) -> void:
	for k in data_map.keys():
		vars[k] = [flags, data_map[k]]

func def_fn(flags: Array[Lisper.VarFlag], type: Lisper.FnType, name: StringName, handle: Variant) -> void:
	vars[name] = [flags, [type, handle]]

func def_fns(flags: Array[Lisper.VarFlag], type: Lisper.FnType, handle_map: Dictionary) -> void:
	for k in handle_map.keys():
		vars[k] = [flags, [type, handle_map[k]]]

func eval(expr: String) -> Variant:
	var tokens = Lisper.tokenize(expr)
	source = expr
	if tokens != null:
		var res = exec(tokens)
		source = null
		return res
	else:
		push_error("failed to tokenize expression")
		return null

func exec(nodes: Array) -> Variant:
	return nodes.map(exec_node)

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
		printerr(msg)
	print('')

func exec_node(node: Array) -> Variant:
	match node[0]:
		Lisper.TType.TOKEN:
			return get_var(node[1])
		Lisper.TType.RAW, Lisper.TType.NUMBER, Lisper.TType.BOOL, Lisper.TType.KEYWORD, Lisper.TType.STRING:
			return node[1]
		Lisper.TType.LIST:
			var head = node[1][0]
			var body = (node[1] as Array).slice(1)
			var handle = exec_node(head)
			if handle is Array:
				return call_rawfn(handle, body)
			elif handle == null:
				log_error(node, str("call handle not found: ", head))
			else:
				log_error(node, str("unexpected call handle: ", handle))
			return null
		Lisper.TType.ARRAY:
			return (node[1] as Array).map(exec_node)
		Lisper.TType.MAP:
			return exec_map_part(node[1])
	log_error(node, str("unknown node: ", node))
	return null

func exec_as_keyword(node: Array) -> Variant:
	match node[0]:
		Lisper.TType.TOKEN, Lisper.TType.KEYWORD:
			return node[1]
		Lisper.TType.STRING:
			return StringName(node[1])
	log_error(node, str("unable to convert node to keyword: ", node))
	return null

@warning_ignore("integer_division")
func exec_map_part(pairs: Array) -> Dictionary:
	var res := {}
	for i in pairs.size() / 2:
		var k = exec_as_keyword(pairs[2 * i])
		var v = exec_node(pairs[2 * i + 1])
		res[k] = v
	return res

func call_rawfn(handle: Array, body: Array) -> Variant:
	match handle[0]:
		Lisper.FnType.GD_RAW, Lisper.FnType.GD_RAW_PURE:
			return handle[1].call(self, body)
		Lisper.FnType.GD_MACRO:
			return exec_node(handle[1].call(body))
		Lisper.FnType.GD_CALL, Lisper.FnType.GD_CALL_PURE:
			return handle[1].callv(body.map(exec_node))
		Lisper.FnType.LP_CALL:
			var fctx := fork()
			var args := handle[1] as Array
			if args.size() != body.size():
				push_error("argument list not match expect ", args.size(), " found ", body.size())
				return null
			var vargs := body.map(exec_node)
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			return fctx.exec(handle[2])[-1]
		_:
			push_error("unknown call handle type: ", handle)
			return null

func call_fn(handle: Array, vargs: Array) -> Variant:
	match handle[0]:
		Lisper.FnType.GD_RAW, Lisper.FnType.GD_RAW_PURE:
			return handle[1].call(self, vargs.map(Lisper.Raw))
		Lisper.FnType.GD_MACRO:
			return exec_node(handle[1].call(vargs.map(Lisper.Raw)))
		Lisper.FnType.GD_CALL, Lisper.FnType.GD_CALL_PURE:
			return handle[1].callv(vargs)
		Lisper.FnType.LP_CALL:
			var fctx := fork()
			var args := handle[1] as Array
			if args.size() != vargs.size():
				push_error("argument list not match expect ", args.size(), " found ", vargs.size())
				return null
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			return fctx.exec(handle[2])[-1]
		_:
			push_error("unknown call handle type: ", handle)
			return null

func call_anyway(handle: Variant, vargs: Array) -> Variant:
	if handle is Callable:
		return handle.callv(vargs)
	if handle is Array:
		return call_fn(handle, vargs)
	push_error("unknown call handle type: ", handle)
	return null

func eval_async(expr: String) -> Variant:
	var tokens = Lisper.tokenize(expr)
	source = expr
	if tokens != null:
		var res = await exec_async(tokens)
		source = null
		return res
	else:
		push_error("failed to tokenize expression")
		return null

func exec_async(nodes: Array) -> Variant:
	var res := []
	res.resize(nodes.size())
	for idx in nodes.size():
		res[idx] = await exec_node_async(nodes[idx])
	return res

func exec_node_async(node: Array) -> Variant:
	match node[0]:
		Lisper.TType.TOKEN:
			return get_var(node[1])
		Lisper.TType.RAW, Lisper.TType.NUMBER, Lisper.TType.BOOL, Lisper.TType.KEYWORD, Lisper.TType.STRING:
			return node[1]
		Lisper.TType.LIST:
			var head = node[1][0]
			var body = (node[1] as Array).slice(1)
			var handle = await exec_node_async(head)
			if handle is Array:
				return await call_rawfn_async(handle, body)
			elif handle == null:
				log_error(node, str("call handle not found: ", head))
			else:
				log_error(node, str("unexpected call handle: ", handle))
			return null
		Lisper.TType.ARRAY:
			var res := []
			var body := node[1] as Array
			res.resize(body.size())
			for idx in body.size():
				res[idx] = await exec_node_async(body[idx])
			return res
		Lisper.TType.MAP:
			return await exec_map_part_async(node[1])
	log_error(node, str("unknown node: ", node))
	return null

@warning_ignore("integer_division")
func exec_map_part_async(pairs: Array) -> Dictionary:
	var res := {}
	for i in pairs.size() / 2:
		var k = exec_as_keyword(pairs[2 * i])
		var v = await exec_node_async(pairs[2 * i + 1])
		res[k] = v
	return res

func call_rawfn_async(handle: Array, body: Array) -> Variant:
	match handle[0]:
		Lisper.FnType.GD_RAW, Lisper.FnType.GD_RAW_PURE:
			return await handle[1].call(self, body)
		Lisper.FnType.GD_MACRO:
			return await exec_node_async(handle[1].call(body))
		Lisper.FnType.GD_CALL, Lisper.FnType.GD_CALL_PURE:
			var vargs := []
			vargs.resize(body.size())
			for idx in body.size():
				vargs[idx] = await exec_node_async(body[idx])
			return await handle[1].callv(vargs)
		Lisper.FnType.LP_CALL:
			var fctx := fork()
			var args := handle[1] as Array
			if args.size() != body.size():
				push_error("argument list not match expect ", args.size(), " found ", body.size())
				return null
			var vargs := []
			vargs.resize(body.size())
			for idx in body.size():
				vargs[idx] = await exec_node_async(body[idx])
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			return (await fctx.exec_async(handle[2]))[-1]
		_:
			push_error("unknown call handle type: ", handle)
			return null

func call_fn_async(handle: Array, vargs: Array) -> Variant:
	match handle[0]:
		Lisper.FnType.GD_RAW, Lisper.FnType.GD_RAW_PURE:
			return await handle[1].call(self, vargs.map(Lisper.Raw))
		Lisper.FnType.GD_MACRO:
			return await exec_node_async(handle[1].call(vargs.map(Lisper.Raw)))
		Lisper.FnType.GD_CALL, Lisper.FnType.GD_CALL_PURE:
			return await handle[1].callv(vargs)
		Lisper.FnType.LP_CALL:
			var fctx := fork()
			var args := handle[1] as Array
			if args.size() != vargs.size():
				push_error("argument list not match expect ", args.size(), " found ", vargs.size())
				return null
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			return (await fctx.exec_async(handle[2]))[-1]
		_:
			push_error("unknown call handle type: ", handle)
			return null

func call_anyway_async(handle: Variant, vargs: Array) -> Variant:
	if handle is Callable:
		return await handle.callv(vargs)
	if handle is Array:
		return await call_fn(handle, vargs)
	push_error("unknown call handle type: ", handle)
	return null
