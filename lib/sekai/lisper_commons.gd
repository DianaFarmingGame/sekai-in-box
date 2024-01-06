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

func def_commons(context: LisperContext) -> void:
	context.def_vars([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], {
		&"raw": Lisper.FuncGDRawPure( func (_ctx, body: Array) -> Array:
			return body),
		&"block": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			return ctx.exec(body)[-1] if body.size() > 0 else null),
		&"if": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			if ctx.exec_node(body[0]):
				return ctx.exec_node(body[1])
			elif body.size() > 2:
				return ctx.exec_node(body[2])
			return null),
		&"loop": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			while true:
				for node in body:
					ctx.exec_node(node)
			return null),
		&"loop*": Lisper.FuncGDRaw( func (ctx: ProcedureContext, body: Array) -> Variant:
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
			var vctx := ProcedureCommons.fork()
			body = body.map(ctx.exec_node)
			var handle = body[0]
			var args = body.slice(1)
			vctx.call_fn_async(handle, args)
			return vctx),
		&"array/concat": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Array:
			var res := []
			body = body.map(ctx.exec_node)
			for v in body:
				assert(v is Array)
				res.append_array(v)
			return res),
		&"array/map": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			var ary := ctx.exec_node(body[0]) as Array
			var handle = ctx.exec_node(body[1])
			return ary.map(func (e): return ctx.call_fn(handle, [e]))),
		&"array/slice": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
			var ary := ctx.exec_node(body[0]) as Array
			var begin := 0
			var end := ary.size()
			var step := 1
			var deep := false
			if body.size() >= 2: begin = ctx.exec_node(body[1]);\
			if body.size() >= 3: end = ctx.exec_node(body[2]);\
			if body.size() >= 4: step = ctx.exec_node(body[3]);\
			if body.size() >= 5: deep = ctx.exec_node(body[4])
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
			var vname = body[0][1]
			if vname is String or vname is StringName:
				var data = ctx.exec_node(body[1])
				ctx.def_var([], vname, data) # TODO
			else:
				ctx.log_error(body[0], str("defvar: ", body[0], " is not a valid token"))),
		&"do": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Variant:
			var this := ctx.exec_node(body[0]) as Mono
			var act_name := ctx.exec_as_keyword(body[1]) as StringName
			var action = this.getp(&"actions").get(act_name)
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
		&"destroy": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> void:
			var this := ctx.exec_node(body[0]) as Mono
			this.destroy()),
		&"queue_destroy": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> void:
			var this := ctx.exec_node(body[0]) as Mono
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
		&"+": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x + y),
		&"-": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x - y),
		&"*": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x * y),
		&"/": Lisper.FuncGDCallPure( func (x, y) -> Variant:
			return x / y),
		&"@": Lisper.FuncGDCallPure( func (src, ref) -> Variant:
			return src[ref]),
		&"@=": Lisper.FuncGDCallPure( func (src, ref, value) -> void:
			src[ref] = value),
		&"prop/setp": Lisper.FuncGDCallPure(Prop.setp),
		&"prop/pushs": Lisper.FuncGDCallPure(Prop.pushs),
		&"prop/puts": Lisper.FuncGDCallPure(Prop.puts),
		&"prop/mergep": Lisper.FuncGDCallPure(Prop.mergep),
		&"debug": Lisper.FuncGDCall( func (value: Variant) -> Variant:
			breakpoint
			return value),
	})
