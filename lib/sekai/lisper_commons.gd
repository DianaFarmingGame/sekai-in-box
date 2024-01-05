extends Node

var CommonContext: LisperContext

func eval(expr: String) -> Variant:
	var ctx := CommonContext.fork()
	var res = ctx.eval(expr)
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
					&"": i += 1; continue
					&":eval":
						var res = ctx.exec_node(body[i])
						body[i] = res if is_raw else Lisper.Raw(res)
						act_type = &""; is_raw = false
						i += 1; continue
					&":expand":
						var res := ctx.exec_node(body.pop_at(i)) as Array
						var nbody = body.slice(0, i)
						nbody.append_array(res if is_raw else res.map(Lisper.Raw))
						nbody.append_array(body.slice(i))
						body = nbody
						act_type = &""; is_raw = false
						i += res.size(); continue
			return [node[0], body]
	return node

func def_commons(context: LisperContext) -> void:
	context.def_vars([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], {
		&"raw": Lisper.FuncGDRawPure( func (_ctx, body: Array) -> Array:
			return body[0]),
		&"raw<-": Lisper.FuncGDCallPure( func (value: Variant) -> Array:
			return Lisper.Raw(value)),
		&"raw->string": Lisper.FuncGDCallPure(Lisper.stringify),
		&"raw/echo": Lisper.FuncGDMacro( func (body: Array) -> Array:
			return Lisper.Call(&"echo", [[
				Lisper.Call(&"raw->string", [body]),
			]])),
		&"display": Lisper.FuncGDMacro( func (body: Array) -> Array:
			return Lisper.Call(&"echo", [[
				Lisper.Call(&"raw->string", [[
					Lisper.Call(&"raw", [body]),
				]]),
			]])),
		&"template": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Array:
			return template(ctx, body[0])),
		&"block": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			return ctx.exec(body)[-1] if body.size() > 0 else null),
		&"=>": Lisper.FuncGDMacro( func (body: Array) -> Array:
			var inner = body[0]
			for step in body.slice(1):
				step = step.duplicate()
				step[1] = step[1].duplicate()
				step[1].insert(1, inner)
				inner = step
			return inner),
		&"if": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			if ctx.exec_node(body[0]):
				return ctx.exec_node(body[1])
			elif body.size() > 2:
				return ctx.exec_node(body[2])
			return null),
		&"switch": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			var value = ctx.exec_node(body[0])
			for i in (body.size() - 1) / 2:
				var caser = ctx.exec_node(body[2 * i + 1])
				if is_same(caser, true) or is_same(caser, value):
					return ctx.exec_node(body[2 * i + 2])
			return null),
		&"loop": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			while true:
				for node in body:
					ctx.exec_node(node)
			return null),
		&"loop*": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Variant:
			ctx = ctx.fork()
			var state := [false, false]
			var res = [null]
			var skip_ref := ctx.exec_as_keyword(body[0]) as StringName
			var escape_ref := ctx.exec_as_keyword(body[1]) as StringName
			ctx.def_var([], skip_ref, Lisper.FuncGDCall( func (): state[0] = true ))
			ctx.def_var([], escape_ref, Lisper.FuncGDCall( func (pres = null): res[0] = pres; state[1] = true ))
			while not state[1]:
				for node in body:
					if state[1] or state[0]:
						state[0] = false
						break
					ctx.exec_node(node)
			return res[0]),
		&"unfold": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			var size := int(ctx.exec_node(body[0]))
			var handle = ctx.exec_node(body[1])
			return range(size).map(func (i): return ctx.call_fn(handle, [i]))),
		&"func": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Array:
			var args := []
			var args_src = body[0][1]
			var idx := 0
			while idx < args_src.size():
				var node = args_src[idx]
				args.append(ctx.exec_as_keyword(node))
				idx += 1
			return [Lisper.FnType.LP_CALL, args, body.slice(1)]),
		&"proc": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Array:
			var args := []
			var args_src = body[0][1]
			var idx := 0
			while idx < args_src.size():
				var node = args_src[idx]
				args.append(ctx.exec_as_keyword(node))
				idx += 1
			return [Lisper.FnType.LP_CALL, args, body.slice(1)]),
		&"proc/call": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> ProcedureContext:
			var vctx := ProcedureContext.extend(ctx)
			body = body.map(ctx.exec_node)
			var handle = body[0]
			var args = body.slice(1)
			vctx.call_fn_async(handle, args)
			return vctx),
		&"keyword": Lisper.FuncGDCallPure( func (value: Variant) -> StringName:
			return StringName(value)),
		&"num": Lisper.FuncGDCallPure( func (value: Variant) -> float:
			return float(value)),
		&"array/size": Lisper.FuncGDCallPure( func (ary: Array) -> int:
			return ary.size()),
		&"array/concat": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Array:
			var res := []
			body = body.map(ctx.exec_node)
			for v in body:
				assert(v is Array)
				res.append_array(v)
			return res),
		&"array/flat": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Array:
			var ary := ctx.exec_node(body[0]) as Array
			var res := []
			for item in ary:
				assert(item is Array)
				res.append_array(item)
			return res),
		&"array/map": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Array:
			var ary := ctx.exec_node(body[0]) as Array
			var handle = ctx.exec_node(body[1])
			return ary.map(func (e): return ctx.call_fn(handle, [e]))),
		&"array/filter": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Array:
			var ary := ctx.exec_node(body[0]) as Array
			var handle = ctx.exec_node(body[1])
			return ary.filter(func (e): return ctx.call_fn(handle, [e]))),
		&"array/slice": Lisper.FuncGDCallPure( func (ary: Array, begin := 0, end := ary.size(), step := 1, deep := false) -> Array:
			return ary.slice(begin, end, step, deep)),
		&"array/let": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			ctx = ctx.fork()
			var ary := ctx.exec_node(body[0]) as Array
			var defs := body[1][1].map(func (node): return ctx.exec_as_keyword(node)) as Array
			for i in defs.size():
				ctx.def_var([], defs[i], ary[i])
			var res = null
			for node in body.slice(2):
				res = ctx.exec_node(node)
			return res),
		&"array/map-let": Lisper.FuncGDMacro( func (body: Array) -> Array:
			return Lisper.Call(&"array/map", [[
				body[0],
				Lisper.Func([&"$item"], [[
					Lisper.Call(&"array/let", [[Lisper.Token(&"$item"), body[1]], body.slice(2)])
				]]),
			]])),
		&"array/for": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> void:
			var ary := ctx.exec_node(body[0]) as Array
			var handle = ctx.exec_node(body[1])
			for i in ary.size():
				ctx.call_fn(handle, [i, ary[i]])
			),
		&"dict/for": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> void:
			var dict := ctx.exec_node(body[0]) as Dictionary
			var handle = ctx.exec_node(body[1])
			for key in dict.keys():
				ctx.call_fn(handle, [key, dict[key]])
			),
		&"string/split": Lisper.FuncGDCallPure( func (pstr: String, split: String) -> Array:
			return Array(pstr.split(split))),
		&"string/trim": Lisper.FuncGDCallPure( func (pstr: String) -> String:
			return pstr.strip_edges()),
		&"echo": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Variant:
			var msg := []
			var res
			for node in body:
				res = ctx.exec_node(node)
				msg.append(str(res))
			print(' '.join(msg))
			return res),
		&"eval": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Variant:
			var result = null
			for node in body:
				var res = ctx.exec_node(node)
				result = ctx.exec_node(res)
			return result),
		&"defvar": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> void:
			var vname := ctx.exec_as_keyword(body[0]) as StringName
			var data = ctx.exec_node(body[1])
			ctx.def_var([], vname, data)), # TODO
		&"do": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Variant:
			var this := ctx.exec_node(body[0]) as Mono
			var act_name := ctx.exec_as_keyword(body[1]) as StringName
			var action = this.getp(&"actions").get(act_name)
			if action == null: action = this.getpR(&"actions").get(act_name)
			var argv := [Lisper.Raw(this.sekai), Lisper.Raw(this)]
			argv.append_array(body.slice(2))
			return ctx.call_rawfn(action, argv)),
		&"callm": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Variant:
			var this := ctx.exec_node(body[0]) as Mono
			var method := ctx.exec_as_keyword(body[1]) as StringName
			var argv := ctx.exec_node(body.slice(2)) as Array
			return this.applym(method, argv)),
		&"getp": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Variant:
			var this := ctx.exec_node(body[0]) as Mono
			var key := ctx.exec_as_keyword(body[1]) as StringName
			return this.getp(key)),
		&"setp": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> void:
			var this := ctx.exec_node(body[0]) as Mono
			var key := ctx.exec_as_keyword(body[1]) as StringName
			var value = ctx.exec_node(body[1])
			this.setp(key, value)),
		&"destroy": Lisper.FuncGDRaw( func (this: Mono) -> void:
			this.destroy()),
		&"queue_destroy": Lisper.FuncGDCall( func (this: Mono) -> void:
			this.destroy.call_deferred()),
		&"vec2": Lisper.FuncGDCallPure( func (x: float, y: float) -> Vector2:
			return Vector2(x, y)),
		&"vec3": Lisper.FuncGDCallPure( func (x: float, y: float, z: float) -> Vector3:
			return Vector3(x, y, z)),
		&"rect2": Lisper.FuncGDCallPure( func (x: float, y: float, w: float, h: float) -> Rect2:
			return Rect2(x, y, w, h)),
		&"color": Lisper.FuncGDCallPure( func (r_c = null, g_a = null, b = null, a = null) -> Color:
			if r_c == null: return Color()
			if g_a == null: return Color(r_c)
			if b == null: return Color(r_c, g_a)
			if a == null: return Color(r_c, g_a, b)
			return Color(r_c, g_a, b, a)),
		&"set": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> void:
			var vname := ctx.exec_as_keyword(body[0]) as StringName
			var data = ctx.exec_node(body[1])
			ctx.set_var(vname, data)),
		&"+1": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> void:
			var vname := ctx.exec_as_keyword(body[0]) as StringName
			ctx.set_var(vname, ctx.get_var(vname) + 1)),
		&":-1": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> void:
			var vname := ctx.exec_as_keyword(body[0]) as StringName
			ctx.set_var(vname, ctx.get_var(vname) - 1)),
		&"+": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x + y),
		&":-": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x - y),
		&"*": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x * y),
		&"/": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x / y),
		&"<": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x < y),
		&"<=": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x <= y),
		&">": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x > y),
		&">=": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x >= y),
		&"==": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x == y),
		&"!=": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x != y),
		&"@": Lisper.FuncGDCallPure( func (src, ref) -> Variant:
			return src[ref]),
		&"@=": Lisper.FuncGDCallPure( func (src, ref, value) -> void:
			src[ref] = value),
		&"and": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			var res = true
			for expr in body:
				res = ctx.exec_node(expr)
				if not res: return res
			return res),
		&"or": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			var res = false
			for expr in body:
				res = ctx.exec_node(expr)
				if res: return res
			return res),
		&"not": Lisper.FuncGDCallPure( func (v) -> bool:
			return not v),
		&"prop/setp": Lisper.FuncGDCallPure(Prop.setp),
		&"prop/pushs": Lisper.FuncGDCallPure(Prop.pushs),
		&"prop/puts": Lisper.FuncGDCallPure(Prop.puts),
		&"prop/mergep": Lisper.FuncGDCallPure(Prop.mergep),
		&"debug": Lisper.FuncGDCall( func (value: Variant) -> Variant:
			breakpoint
			return value),
	})
