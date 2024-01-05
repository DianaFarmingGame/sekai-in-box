class_name ProcedureContext extends LisperContext

var stopped := false

static func extend(ctx: LisperContext) -> LisperContext:
	var nctx := ProcedureContext.new()
	nctx.parent = ctx
	return nctx

func clone() -> LisperContext:
	var ctx := ProcedureContext.new()
	ctx.parent = parent
	ctx.vars = vars.duplicate(true)
	ctx.source = source
	return ctx

func fork() -> LisperContext:
	var ctx := ProcedureContext.new()
	ctx.parent = self
	return ctx

func exec_async(nodes: Array) -> Variant:
	var res := []
	res.resize(nodes.size())
	for idx in nodes.size():
		if stopped: return
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
			if stopped: return
			var handle = await exec_node_async(head)
			if handle is Array:
				if stopped: return
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
				if stopped: return
				res[idx] = await exec_node_async(body[idx])
			return res
		Lisper.TType.MAP:
			if stopped: return
			return await exec_map_part_async(node[1])
	log_error(node, str("unknown node: ", node))
	return null

@warning_ignore("integer_division")
func exec_map_part_async(pairs: Array) -> Dictionary:
	var res := {}
	for i in pairs.size() / 2:
		var k = exec_as_keyword(pairs[2 * i])
		if stopped: return {}
		var v = await exec_node_async(pairs[2 * i + 1])
		res[k] = v
	return res

func call_rawfn_async(handle: Array, body: Array) -> Variant:
	match handle[0]:
		Lisper.FnType.GD_RAW, Lisper.FnType.GD_RAW_PURE:
			if stopped: return
			return await handle[1].call(self, body)
		Lisper.FnType.GD_MACRO:
			if stopped: return
			return await exec_node_async(handle[1].call(body))
		Lisper.FnType.GD_CALL, Lisper.FnType.GD_CALL_PURE:
			var vargs := []
			vargs.resize(body.size())
			for idx in body.size():
				if stopped: return
				vargs[idx] = await exec_node_async(body[idx])
			if stopped: return
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
				if stopped: return
				vargs[idx] = await exec_node_async(body[idx])
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			if stopped: return
			return (await fctx.exec_async(handle[2]))[-1]
		_:
			push_error("unknown call handle type: ", handle)
			return null

func call_fn_async(handle: Array, vargs: Array) -> Variant:
	match handle[0]:
		Lisper.FnType.GD_RAW, Lisper.FnType.GD_RAW_PURE:
			if stopped: return
			return await handle[1].call(self, vargs.map(Lisper.Raw))
		Lisper.FnType.GD_MACRO:
			if stopped: return
			return await exec_node_async(handle[1].call(vargs.map(Lisper.Raw)))
		Lisper.FnType.GD_CALL, Lisper.FnType.GD_CALL_PURE:
			if stopped: return
			return await handle[1].callv(vargs)
		Lisper.FnType.LP_CALL:
			var fctx := fork()
			var args := handle[1] as Array
			if args.size() != vargs.size():
				push_error("argument list not match expect ", args.size(), " found ", vargs.size())
				return null
			for iarg in args.size():
				fctx.def_var([], args[iarg], vargs[iarg])
			if stopped: return
			return (await fctx.exec_async(handle[2]))[-1]
		_:
			push_error("unknown call handle type: ", handle)
			return null
