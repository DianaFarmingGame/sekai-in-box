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

func gsm(): return ['

defvar (var :const defvar)

defunc (fn :const :gd :macro ',
	func (ctx: LisperContext, body: Array) -> Array:
		var head = ctx.strip_flags(body)[1][0]
		if Lisper.is_array(head) or Lisper.is_raw(head):
			return Lisper.apply(&"func", [body])
		else:
			return Lisper.apply(&"defunc", [body])
,')

defunc (raw :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.Raw(body[0])
,')

defunc (raw<- :const :gd :pure ',
	func (value: Variant) -> Array:
		return Lisper.Raw(value)
,')

defunc (raw->string :const :gd :apply :pure ',
	func (value: Variant) -> Array:
		return Lisper.Raw(value)
,')

defunc (display :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"echo", [[
			Lisper.apply(&"raw->string", [[
				Lisper.apply(&"raw", [body]),
			]]),
		]])
,')

defunc (compile :const :gd :apply :pure ',
	func (ctx: LisperContext, args: Array) -> Array:
		return await ctx.compile(args[0])
,')

defunc (template :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime:
			var res := await compile_template(ctx, body[0])
			if res[0]:
				return Lisper.RawOverride(Lisper.Raw(res[1]))
			else:
				return [res[1]]
		else:
			return await template(ctx, body[0])
,')

defunc (block :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime:
			return await LisperCommons.compile_block(ctx, body)
		else:
			return (await ctx.execs(body))[-1] if body.size() > 0 else null
,')

defunc (=> :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		var inner = body[0]
		for step in body.slice(1):
			step = step.duplicate()
			step[1] = step[1].duplicate()
			step[1].insert(1, inner)
			inner = step
		return inner
,')

defunc (if :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
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
			return null
,')

defunc (switch :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
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
						if is_same(caser, true) or Lisper.is_same_approx(caser, value):
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
				if is_same(caser, true) or Lisper.is_same_approx(caser, value):
					return await ctx.exec(body[2 * i + 2])
			return null
,')

defunc (loop :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime:
			body = await ctx.compiles(body)
			body = body.filter(func (n): return not Lisper.is_raw(n))
			return body
		else:
			while true:
				await ctx.execs(body)
			return null
,')

defunc (loop* :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		ctx = ctx.fork()
		var state := [false, false]
		var res = [null]
		var skip_ref := await ctx.exec_as_keyword(body[0]) as StringName
		var escape_ref := await ctx.exec_as_keyword(body[1]) as StringName
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
			return res[0]
,')

defunc (keyword :const :gd :pure ',
	func (value: Variant) -> StringName:
		return StringName(value)
,')

defunc (num :const :gd :pure ',
	func (value: Variant) -> float:
		return float(value)
,')

defunc (echo :const :gd :apply ',
	func (ctx: LisperContext, args: Array) -> Variant:
		var msg := ' '.join(args.map(func (e): return str(e)))
		var lines := msg.split('\n')
		print('\n'.join(Array(lines).map(func (l): return ctx.print_head + l)))
		return args[-1] if args.size() > 0 else null
,')

defunc (echo_val :const :gd :apply ',
	func (ctx: LisperContext, args: Array) -> Variant:
		var msg := ' '.join(args.map(func (e): return ctx.stringify_raw(e)))
		var lines := msg.split('\n')
		print('\n'.join(Array(lines).map(func (l): return ctx.print_head + l)))
		return args[-1] if args.size() > 0 else null
,')

defunc (echo_raw :const :gd :apply ',
	func (ctx: LisperContext, args: Array) -> Variant:
		var msg := ' '.join(args.map(func (e): return ctx.stringify(e)))
		var lines := msg.split('\n')
		print('\n'.join(Array(lines).map(func (l): return ctx.print_head + l)))
		return args[-1] if args.size() > 0 else null
,')

defunc (echo_rich :const :gd :apply ',
	func (ctx: LisperContext, args: Array) -> Variant:
		var msg := ' '.join(args.map(func (e): return str(e)))
		var lines := msg.split('\n')
		print_rich('\n'.join(Array(lines).map(func (l): return ctx.print_head + l)))
		return args[-1] if args.size() > 0 else null
,')

defunc (eval :const :gd :apply ',
	func (ctx: LisperContext, args: Array) -> Variant:
		return (await ctx.execs(args))[-1]
,')

defunc (debug :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		breakpoint
		if comptime: return await ctx.compiles(body)
		return (await ctx.execs(body))[-1]
,')

defunc (go :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await ctx.compiles(body)
		return body.map(ctx.exec)
,')

defunc (+ :const :gd :pure ', func (a, b): return a + b ,')
defunc (,- :const :gd :pure ', func (a, b): return a - b ,')
defunc (* :const :gd :pure ', func (a, b): return a * b ,')
defunc (/ :const :gd :pure ', func (a, b): return a / b ,')

defunc (< :const :gd :pure ', func (a, b): return a < b ,')
defunc (<= :const :gd :pure ', func (a, b): return a <= b ,')
defunc (> :const :gd :pure ', func (a, b): return a > b ,')
defunc (>= :const :gd :pure ', func (a, b): return a >= b ,')
defunc (== :const :gd :pure ', func (a, b): return a == b ,')
defunc (!= :const :gd :pure ', func (a, b): return a != b ,')
defunc (not :const :gd :pure ', func (v): return not v ,')

defunc (@ :const :gd :pure ', func (src, ref): return src[ref] ,')
defunc (@= :const :gd :pure ', func (src, ref, value): src[ref] = value ,')

defunc (and :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
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
			return res
,')

defunc (or :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
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
			return res
,')

defunc (+1 :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_1(ctx, body)
		else:
			var vname := await ctx.exec_as_keyword(body[0]) as StringName
			ctx.set_var(vname, ctx.get_var(vname) + 1)
			return null
,')

defunc (,-1 :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_1(ctx, body)
		else:
			var vname := await ctx.exec_as_keyword(body[0]) as StringName
			ctx.set_var(vname, ctx.get_var(vname) - 1)
			return null
,')

defunc (vec2 :const :gd :pure ', func (x, y): return Vector2(x, y) ,')
defunc (vec3 :const :gd :pure ', func (x, y, z): return Vector3(x, y, z) ,')
defunc (rect2 :const :gd :pure ', func (x, y, w, h): return Rect2(x, y, w, h) ,')
defunc (color :const :gd :pure ',
	func (r_c = null, g_a = null, b = null, a = null) -> Color:
		if r_c == null: return Color()
		if g_a == null: return Color(r_c)
		if b == null: return Color(r_c, g_a)
		if a == null: return Color(r_c, g_a, b)
		return Color(r_c, g_a, b, a)
,')

']
