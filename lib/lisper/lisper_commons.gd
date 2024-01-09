extends Node

var CommonContext: LisperContext

func eval(expr: String) -> Variant:
	var ctx := CommonContext.fork()
	var res = await ctx.eval(expr)
	return [ctx, res]

func fork() -> LisperContext:
	return CommonContext.fork()

func clone() -> LisperContext:
	return CommonContext.clone()

func _init() -> void:
	CommonContext = LisperContext.new()
	def_commons(CommonContext)

# Template 语法
#   :eval   执行随后的元素并转换为Raw格式
#   :expand 执行随后的元素并将结果数组的各元素转换为Raw格式后依次插入
#   :raw    为随后的操作保留原格式

func template(ctx: LisperContext, node: Array) -> Array:
	match node[0]:
		Lisper.TType.LIST, Lisper.TType.ARRAY, Lisper.TType.MAP:
			var body := (node[1] as Array).duplicate()
			var act_type := &""
			var is_raw := false
			var i := 0
			while i < body.size():
				var n := body[i] as Array
				if n[0] == Lisper.TType.TOKEN:
					match n[1]:
						&":eval":
							body.remove_at(i)
							act_type = &":eval"
							continue
						&":expand":
							body.remove_at(i)
							act_type = &":expand"
							continue
						&":raw":
							body.remove_at(i)
							is_raw = true
							continue
				match act_type:
					&"": body[i] = await template(ctx, body[i]); i += 1; continue
					&":eval":
						var res = await ctx.exec(body[i])
						body[i] = res if is_raw else Lisper.Raw(res)
						act_type = &""; is_raw = false
						i += 1; continue
					&":expand":
						var res := await ctx.exec(body.pop_at(i)) as Array
						var nbody = body.slice(0, i)
						nbody.append_array(res if is_raw else res.map(Lisper.Raw))
						nbody.append_array(body.slice(i))
						body = nbody
						act_type = &""; is_raw = false
						i += res.size(); continue
			return [node[0], body]
	return node

func compile_template(ctx: LisperContext, node: Array) -> Array:
	match node[0]:
		Lisper.TType.LIST, Lisper.TType.ARRAY, Lisper.TType.MAP:
			var is_pure := true
			var body := (node[1] as Array).duplicate()
			var act_type := &""
			var is_raw := false
			var i := 0
			var acts := []
			while i < body.size():
				var n := body[i] as Array
				if n[0] == Lisper.TType.TOKEN:
					match n[1]:
						&":eval":
							act_type = &":eval"
							acts.append(i)
							i += 1
							continue
						&":expand":
							act_type = &":expand"
							acts.append(i)
							i += 1
							continue
						&":raw":
							is_raw = true
							acts.append(i)
							i += 1
							continue
				match act_type:
					&"":
						var res := await compile_template(ctx, body[i])
						if not res[0]: is_pure = false
						body[i] = res[1]
						i += 1; continue
					&":eval":
						var cnode := await ctx.compile(body[i])
						if Lisper.is_raw(cnode):
							var res = cnode[1]
							body[i] = res if is_raw else Lisper.Raw(res)
							acts.reverse()
							for idx in acts: body.remove_at(idx)
							i -= acts.size()
						else:
							is_pure = false
							body[i] = cnode
						act_type = &""; is_raw = false; acts = []
						i += 1; continue
					&":expand":
						var cnode := await ctx.compile(body[i])
						if Lisper.is_raw(cnode):
							var res := cnode[1] as Array
							body.remove_at(i)
							var nbody = body.slice(0, i)
							nbody.append_array(res if is_raw else res.map(Lisper.Raw))
							nbody.append_array(body.slice(i))
							body = nbody
							acts.reverse()
							for idx in acts: body.remove_at(idx)
							i -= acts.size()
							i += res.size() - 1
						else:
							is_pure = false
							body[i] = cnode
							i += 1
						act_type = &""; is_raw = false; acts = []
						continue
			return [is_pure, [node[0], body]]
	return [true, node]

func compile_block(ctx: LisperContext, body: Array) -> Array:
	body = await ctx.compiles(body)
	var res = body[-1]
	var tbody := body.slice(0, -1).filter(func (n): return not Lisper.is_raw(n))
	if tbody.size() == 0:
		return Lisper.RawOverride(res)
	tbody.append(res)
	return tbody

func compile_map(ctx: LisperContext, body: Array) -> Array:
	var cdata := []
	var is_key := true
	for n in body:
		if is_key:
			cdata.append(Lisper.Raw(ctx.exec_as_keyword(n)))
		else:
			cdata.append(await ctx.compile(n))
		is_key = not is_key
	return cdata

func compile_keyword_mask_1(ctx: LisperContext, body: Array) -> Array:
	var cdata := []
	var cid := 0
	for n in body:
		if Lisper.is_flag(n): cdata.append(n); continue
		if cid == 0: cdata.append(Lisper.Raw(ctx.exec_as_keyword(n)))
		else: cdata.append(await ctx.compile(n))
		cid += 1
	return cdata

func compile_keyword_mask_01(ctx: LisperContext, body: Array) -> Array:
	var cdata := []
	var cid := 0
	for n in body:
		if Lisper.is_flag(n): cdata.append(n); continue
		if cid == 0: cdata.append(await ctx.compile(n))
		if cid == 1: cdata.append(Lisper.Raw(ctx.exec_as_keyword(n)))
		else: cdata.append(await ctx.compile(n))
		cid += 1
	return cdata

func def_commons(context: LisperContext) -> void:
	context.def_vars([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], {
		&"raw": Lisper.FnGDMacro( func (_ctx, body: Array) -> Array:
			return Lisper.Raw(body[0])),
		&"raw<-": Lisper.FnGDCallP( func (value: Variant) -> Array:
			return Lisper.Raw(value)),
		&"raw->string": Lisper.FnGDApplyP( func (ctx: LisperContext, args: Array) -> String:
			return ctx.stringifys(args)),
		&"display": Lisper.FnGDMacro( func (_ctx, body: Array) -> Array:
			return Lisper.apply(&"echo", [[
				Lisper.apply(&"raw->string", [[
					Lisper.apply(&"raw", [body]),
				]]),
			]])),
		&"compile": Lisper.FnGDApplyP( func (ctx: LisperContext, args: Array) -> Array:
			return await ctx.compile(args[0])),
		&"template": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime:
				var res := await compile_template(ctx, body[0])
				if res[0]:
					return Lisper.RawOverride(Lisper.Raw(res[1]))
				else:
					return [res[1]]
			else:
				return await template(ctx, body[0])),
		&"block": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime:
				return await compile_block(ctx, body)
			else:
				return (await ctx.execs(body))[-1] if body.size() > 0 else null),
		&"=>": Lisper.FnGDMacro( func (_ctx, body: Array) -> Array:
			var inner = body[0]
			for step in body.slice(1):
				step = step.duplicate()
				step[1] = step[1].duplicate()
				step[1].insert(1, inner)
				inner = step
			return inner),
		&"if": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime:
				body = await ctx.compiles(body)
				if Lisper.is_raw(body[0]):
					if body[0][1]:
						return Lisper.RawOverride(body[1])
					else:
						return Lisper.RawOverride(body[2])
				return body
			else:
				if await ctx.exec(body[0]):
					return await ctx.exec(body[1])
				elif body.size() > 2:
					return await ctx.exec(body[2])
				return null),
		&"switch": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime:
				body = await ctx.compiles(body)
				if Lisper.is_raw(body[0]):
					var value = body[0][1]
					body = body.duplicate()
					var i = 0
					while i < (body.size() - 1) / 2:
						var caser_node := body[2 * i + 1] as Array
						var caser_trunk := body[2 * i + 2] as Array
						if Lisper.is_raw(caser_node):
							var caser = caser_node[1]
							if is_same(caser, true) or is_same(caser, value):
								return Lisper.RawOverride(caser_trunk)
							else:
								body.remove_at(2 * i + 2)
								body.remove_at(2 * i + 1)
						else:
							i += 1
				return body
			else:
				var value = await ctx.exec(body[0])
				for i in (body.size() - 1) / 2:
					var caser = await ctx.exec(body[2 * i + 1])
					if is_same(caser, true) or is_same(caser, value):
						return await ctx.exec(body[2 * i + 2])
				return null),
		&"loop": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime:
				body = await ctx.compiles(body)
				body = body.filter(func (n): return not Lisper.is_raw(n))
				return body
			else:
				while true:
					await ctx.execs(body)
				return null),
		&"loop*": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			ctx = ctx.fork()
			var state := [false, false]
			var res = [null]
			var skip_ref := ctx.exec_as_keyword(body[0]) as StringName
			var escape_ref := ctx.exec_as_keyword(body[1]) as StringName
			ctx.def_var([], skip_ref, Lisper.FnGDCall( func (): state[0] = true ))
			ctx.def_var([], escape_ref, Lisper.FnGDCall( func (pres = null): res[0] = pres; state[1] = true ))
			if comptime:
				body = await ctx.compiles(body)
				body = body.filter(func (n): return not Lisper.is_raw(n))
				return body
			else:
				while not state[1]:
					for node in body:
						if state[1] or state[0]:
							state[0] = false
							break
						await ctx.exec(node)
				return res[0]),
		&"unfold": Lisper.FnGDApplyP( func (ctx: LisperContext, args: Array) -> Variant:
			var size := int(args[0])
			var handle = args[1]
			if not ctx.check_valid_handle(handle): return null
			return await Async.array_map(range(size), func (i): return await ctx.call_fn(handle, [i]))),
		&"func": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return body
			var res := ctx.strip_flags(body)
			body = res[1]
			var args := body[0][1].map(ctx.exec_as_keyword) as Array
			var tbody := await ctx.compiles(body.slice(1))
			if res[0].has(&":pure"):
				return Lisper.FnLPCallP(args, tbody)
			return Lisper.FnLPCall(args, tbody)),
		&"factor": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			var res := ctx.strip_flags(body)
			body = res[1]
			var args := body[0][1].map(ctx.exec_as_keyword) as Array
			var tbody := await ctx.compiles(body.slice(1))
			var handle: Array
			if res[0].has(&":pure"):
				handle = Lisper.FnLPCallP(args, tbody)
			else:
				handle = Lisper.FnLPCall(args, tbody)
			if comptime: return Lisper.RawOverride(Lisper.Raw(handle))
			return handle),
		&"func/echo": Lisper.FnGDApply( func (ctx: LisperContext, args: Array) -> Variant:
			var handle := args[0] as Array
			var msg := "func ([" + ' '.join(Lisper.fn_lp_get_args(handle)) + "]\n      " + ctx.stringifys(Lisper.fn_lp_get_body(handle), 6) + ')'
			var lines := msg.split('\n')
			print('\n'.join(Array(lines).map(func (l): return ctx.print_head + l)))
			return args[0]),
		&"keyword": Lisper.FnGDCallP( func (value: Variant) -> StringName:
			return StringName(value)),
		&"num": Lisper.FnGDCallP( func (value: Variant) -> float:
			return float(value)),
		&"array/size": Lisper.FnGDCallP( func (ary: Array) -> int:
			return ary.size()),
		&"array/concat": Lisper.FnGDApplyP( func (_ctx, args: Array) -> Array:
			var res := []
			for v in args:
				assert(v is Array)
				res.append_array(v)
			return res),
		&"array/flat": Lisper.FnGDCallP( func (ary: Array) -> Array:
			var res := []
			for item in ary:
				assert(item is Array)
				res.append_array(item)
			return res),
		&"array/map": Lisper.FnGDApplyP( func (ctx: LisperContext, args: Array) -> Array:
			var ary := args[0] as Array
			var handle = args[1]
			if not ctx.check_valid_handle(handle): return []
			return await Async.array_map(ary, func (e): return await ctx.call_fn(handle, [e]))),
		&"array/filter": Lisper.FnGDApplyP( func (ctx: LisperContext, args: Array) -> Array:
			var ary := args[0] as Array
			var handle = args[1]
			if not ctx.check_valid_handle(handle): return []
			return await Async.array_filter(ary, func (e): return await ctx.call_fn(handle, [e]))),
		&"array/slice": Lisper.FnGDCallP( func (ary: Array, begin := 0, end := ary.size(), step := 1, deep := false) -> Array:
			return ary.slice(begin, end, step, deep)),
		&"array/let": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			ctx = ctx.fork()
			if comptime:
				var defs := body[1][1].map(ctx.exec_as_keyword) as Array
				var ary_node := await ctx.compile(body[0])
				var cdata := [ary_node, Lisper.Array(defs.map(Lisper.Raw))]
				if Lisper.is_raw(ary_node):
					var ary := ary_node[1] as Array
					for i in defs.size():
						ctx.def_const(defs[i], ary[i])
				else:
					for def in defs:
						ctx.def_var([], def, null)
				var res := await compile_block(ctx, body.slice(2))
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
				var defs := (body[1][1] as Array).map(ctx.exec_as_keyword)
				for i in defs.size():
					ctx.def_var([], defs[i], ary[i])
				return (await ctx.execs(body.slice(2)))[-1]),
		&"array/map-let": Lisper.FnGDMacro( func (_ctx, body: Array) -> Array:
			return Lisper.apply(&"array/map", [[
				body[0],
				Lisper.make_func([&"$item"], [[
					Lisper.apply(&"array/let", [[Lisper.Token(&"$item"), body[1]], body.slice(2)])
				]]),
			]])),
		&"array/for": Lisper.FnGDApplyP( func (ctx: LisperContext, args: Array) -> void:
			var ary := args[0] as Array
			var handle = args[1]
			if not ctx.check_valid_handle(handle): return
			for i in ary.size():
				await ctx.call_fn(handle, [i, ary[i]])
			),
		&"dict/for": Lisper.FnGDApplyP( func (ctx: LisperContext, args: Array) -> void:
			var dict := args[0] as Dictionary
			var handle = args[1]
			if not ctx.check_valid_handle(handle): return
			for key in dict.keys():
				await ctx.call_fn(handle, [key, dict[key]])
			),
		&"string/split": Lisper.FnGDCallP( func (pstr: String, split: String) -> Array:
			return Array(pstr.split(split))),
		&"string/trim": Lisper.FnGDCallP( func (pstr: String) -> String:
			return pstr.strip_edges()),
		&"str/concat": Lisper.FnGDCallP( func (ary: Array) -> String:
			var res := ''
			for v in ary:
				assert(v is String)
				res += v
			return res),
		&"echo": Lisper.FnGDApply( func (ctx: LisperContext, args: Array) -> Variant:
			var msg := ' '.join(args.map(func (e): return str(e)))
			var lines := msg.split('\n')
			print('\n'.join(Array(lines).map(func (l): return ctx.print_head + l)))
			return args[-1] if args.size() > 0 else null),
		&"echo_val": Lisper.FnGDApply( func (ctx: LisperContext, args: Array) -> Variant:
			var msg := ' '.join(args.map(func (e): return ctx.stringify_raw(e)))
			var lines := msg.split('\n')
			print('\n'.join(Array(lines).map(func (l): return ctx.print_head + l)))
			return args[-1] if args.size() > 0 else null),
		&"echo_raw": Lisper.FnGDApply( func (ctx: LisperContext, args: Array) -> Variant:
			var msg := ' '.join(args.map(func (e): return ctx.stringify(e)))
			var lines := msg.split('\n')
			print('\n'.join(Array(lines).map(func (l): return ctx.print_head + l)))
			return args[-1] if args.size() > 0 else null),
		&"echo_rich": Lisper.FnGDApply( func (ctx: LisperContext, args: Array) -> Variant:
			var msg := ' '.join(args.map(func (e): return str(e)))
			var lines := msg.split('\n')
			print_rich('\n'.join(Array(lines).map(func (l): return ctx.print_head + l)))
			return args[-1] if args.size() > 0 else null),
		&"eval": Lisper.FnGDApply( func (ctx: LisperContext, args: Array) -> Variant:
			return (await ctx.execs(args))[-1]),
		&"defvar": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await compile_keyword_mask_1(ctx, body)
			var res := ctx.strip_flags(body)
			var flags: Array[Lisper.VarFlag] = []
			for f in res[0]:
				match f:
					&":const": flags.append(Lisper.VarFlag.CONST)
					&":fix": flags.append(Lisper.VarFlag.FIX)
			body = res[1]
			var vname := ctx.exec_as_keyword(body[0]) as StringName
			var data = await ctx.exec(body[1])
			ctx.def_var(flags, vname, data)
			return null),
		&"defunc": Lisper.FnGDMacro( func (ctx: LisperContext, body: Array) -> Array:
			var res := ctx.strip_flags(body)
			var var_flags := []
			var fn_flags := []
			for f in res[0]:
				match f:
					&":const", &":fix": var_flags.append(f)
					&":pure": fn_flags.append(f)
			body = res[1]
			return Lisper.apply(&"defvar", [var_flags.map(Lisper.Token), [
				body[0],
				Lisper.apply(&"func", [fn_flags.map(Lisper.Token), body.slice(1)]),
			]])),
		&"do": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await compile_keyword_mask_01(ctx, body)
			else:
				var this := await ctx.exec(body[0]) as Mono
				var act_name := ctx.exec_as_keyword(body[1]) as StringName
				var action = this.getp(&"actions").get(act_name)
				if action == null: action = this.getpR(&"actions").get(act_name) # FIXME
				var argv := [Lisper.Raw(this.sekai), Lisper.Raw(this)]
				argv.append_array(body.slice(2))
				return await ctx.call_fn_raw(action, argv)),
		&"callm": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await compile_keyword_mask_01(ctx, body)
			else:
				var this := await ctx.exec(body[0]) as Mono
				var method := ctx.exec_as_keyword(body[1]) as StringName
				var argv := await ctx.execs(body.slice(2)) as Array
				return await this.applym(method, argv)),
		&"getp": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await compile_keyword_mask_01(ctx, body)
			else:
				var this := await ctx.exec(body[0]) as Mono
				var key := ctx.exec_as_keyword(body[1]) as StringName
				return this.getp(key)),
		&"setp": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await compile_keyword_mask_01(ctx, body)
			else:
				var this := await ctx.exec(body[0]) as Mono
				var key := ctx.exec_as_keyword(body[1]) as StringName
				var value = await ctx.exec(body[2])
				this.setp(key, value)
				return null),
		&"destroy": Lisper.FnGDCall( func (this: Mono) -> void:
			this.destroy()),
		&"queue_destroy": Lisper.FnGDCall( func (this: Mono) -> void:
			this.destroy.call_deferred()),
		&"vec2": Lisper.FnGDCallP( func (x: float, y: float) -> Vector2:
			return Vector2(x, y)),
		&"vec3": Lisper.FnGDCallP( func (x: float, y: float, z: float) -> Vector3:
			return Vector3(x, y, z)),
		&"rect2": Lisper.FnGDCallP( func (x: float, y: float, w: float, h: float) -> Rect2:
			return Rect2(x, y, w, h)),
		&"color": Lisper.FnGDCallP( func (r_c = null, g_a = null, b = null, a = null) -> Color:
			if r_c == null: return Color()
			if g_a == null: return Color(r_c)
			if b == null: return Color(r_c, g_a)
			if a == null: return Color(r_c, g_a, b)
			return Color(r_c, g_a, b, a)),
		&"set": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await compile_keyword_mask_1(ctx, body)
			else:
				var vname := ctx.exec_as_keyword(body[0]) as StringName
				var data = await ctx.exec(body[1])
				ctx.set_var(vname, data)
				return null),
		&"+1": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await compile_keyword_mask_1(ctx, body)
			else:
				var vname := ctx.exec_as_keyword(body[0]) as StringName
				ctx.set_var(vname, ctx.get_var(vname) + 1)
				return null),
		&":-1": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await compile_keyword_mask_1(ctx, body)
			else:
				var vname := ctx.exec_as_keyword(body[0]) as StringName
				ctx.set_var(vname, ctx.get_var(vname) - 1)
				return null),
		&"+": Lisper.FnGDCallP( func (x, y) -> Variant:
			return x + y),
		&":-": Lisper.FnGDCallP( func (x, y) -> Variant:
			return x - y),
		&"*": Lisper.FnGDCallP( func (x, y) -> Variant:
			return x * y),
		&"/": Lisper.FnGDCallP( func (x, y) -> Variant:
			return x / y),
		&"<": Lisper.FnGDCallP( func (x, y) -> Variant:
			return x < y),
		&"<=": Lisper.FnGDCallP( func (x, y) -> Variant:
			return x <= y),
		&">": Lisper.FnGDCallP( func (x, y) -> Variant:
			return x > y),
		&">=": Lisper.FnGDCallP( func (x, y) -> Variant:
			return x >= y),
		&"==": Lisper.FnGDCallP( func (x, y) -> Variant:
			return x == y),
		&"!=": Lisper.FnGDCallP( func (x, y) -> Variant:
			return x != y),
		&"@": Lisper.FnGDCallP( func (src, ref) -> Variant:
			return src[ref]),
		&"@=": Lisper.FnGDCallP( func (src, ref, value) -> void:
			src[ref] = value),
		&"and": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime:
				var result := Lisper.Raw(true)
				for i in body.size():
					var expr := body[i] as Array
					var res = await ctx.compile(expr)
					if not Lisper.is_raw(res):
						return body.slice(i)
					result = res
					if not result[1]: return Lisper.RawOverride(result)
				return Lisper.RawOverride(result)
			else:
				var res = true
				for expr in body:
					res = await ctx.exec(expr)
					if not res: return res
				return res),
		&"or": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime:
				var result := Lisper.Raw(false)
				for i in body.size():
					var expr := body[i] as Array
					var res = await ctx.compile(expr)
					if not Lisper.is_raw(res):
						return body.slice(i)
					result = res
					if result[1]: return Lisper.RawOverride(result)
				return Lisper.RawOverride(result)
			else:
				var res = false
				for expr in body:
					res = await ctx.exec(expr)
					if res: return res
				return res),
		&"not": Lisper.FnGDCallP( func (v) -> bool:
			return not v),
		&"prop/setp": Lisper.FnGDCallP(Prop.setp),
		&"prop/pushs": Lisper.FnGDCallP(Prop.pushs),
		&"prop/puts": Lisper.FnGDCallP(Prop.puts),
		&"prop/mergep": Lisper.FnGDCallP(Prop.mergep),
		&"debug": Lisper.FnGDCall( func (value: Variant) -> Variant:
			breakpoint
			return value),
		&"go": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await ctx.compiles(body)
			return body.map(ctx.exec)),
		&"delay": Lisper.FnGDCall( func (timeout: float) -> void:
			await get_tree().create_timer(timeout).timeout),
	})
