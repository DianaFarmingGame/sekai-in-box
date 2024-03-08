func gsm(): return ['

defunc (array/size :const :gd :pure ',
	func (ary: Array) -> int:
		return ary.size()
,')

defunc (array/reverse :const :gd :pure ',
	func (ary: Array) -> Array:
		var res := ary.duplicate()
		res.reverse()
		return res
,')

defunc (array/concat :const :gd :apply :pure ',
	func (_ctx, args: Array) -> Array:
		var res := []
		for v in args:
			assert(v is Array)
			res.append_array(v)
		return res
,')

defunc (array/unfold :const :gd :apply :pure ',
	func (ctx: LisperContext, args: Array) -> Variant:
		var size := int(args[0])
		var handle = args[1]
		if not ctx.check_valid_handle(handle): return null
		return await Async.array_map(range(size), func (i): return await ctx.call_fn(handle, [i]))
,')

defunc (array/map :const :gd :apply :pure ',
	func (ctx: LisperContext, args: Array) -> Array:
		var ary := args[0] as Array
		var handle = args[1]
		if not ctx.check_valid_handle(handle): return []
		return await Async.array_map(ary, func (e): return await ctx.call_fn(handle, [e]))
,')

defunc (array/filter :const :gd :apply :pure ',
	func (ctx: LisperContext, args: Array) -> Array:
		var ary := args[0] as Array
		var handle = args[1]
		if not ctx.check_valid_handle(handle): return []
		return await Async.array_filter(ary, func (e): return await ctx.call_fn(handle, [e]))
,')

defunc (array/for :const :gd :apply :pure ',
	func (ctx: LisperContext, args: Array) -> void:
		var ary := args[0] as Array
		var handle = args[1]
		if not ctx.check_valid_handle(handle): return
		for i in ary.size():
			await ctx.call_fn(handle, [i, ary[i]])
,')

defunc (array/flat :const :gd :pure ',
	func (ary: Array) -> Array:
		var res := []
		for item in ary:
			assert(item is Array)
			res.append_array(item)
		return res
,')

defunc (array/slice :const :gd :pure ',
	func (ary: Array, begin := 0, end := ary.size(), step := 1, deep := false) -> Array:
		return ary.slice(begin, end, step, deep)
,')

defunc (array/let :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		ctx = ctx.fork()
		if comptime:
			var defs := await Async.array_map(body[1][1], ctx.exec_as_keyword)
			var ary_node := await ctx.compile(body[0])
			var cdata := [ary_node, Lisper.Array(defs.map(Lisper.Raw))]
			if Lisper.is_raw(ary_node):
				var ary := ary_node[1] as Array
				for i in defs.size():
					ctx.def_const(defs[i], ary[i])
			else:
				for def in defs:
					ctx.def_var([], def, null)
			var res := await LisperCommons.compile_block(ctx, body.slice(2))
			if Lisper.is_raw_override(res):
				if Lisper.is_raw(res[1]):
					return res
				else:
					cdata.append(res[1])
			else:
				cdata.append_array(res)
			return cdata
		else:
			var ary := await ctx.exec(body[0]) as Array
			var defs := await Async.array_map(body[1][1], ctx.exec_as_keyword)
			for i in defs.size():
				ctx.def_var([], defs[i], ary[i])
			return (await ctx.execs(body.slice(2)))[-1]
,')

defunc (array/map-let :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"array/map", [[
			body[0],
			Lisper.make_func([&"$item"], [[
				Lisper.apply(&"array/let", [[Lisper.Token(&"$item"), body[1]], body.slice(2)])
			]]),
		]])
,')

defunc (array->dict :const :gd :pure ',
	func (ary: Array) -> Dictionary:
		var result := {}
		for entry in ary:
			result[entry[0]] = entry[1]
		return result
,')

']
