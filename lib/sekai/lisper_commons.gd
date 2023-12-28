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

func def_commons(ctx: LisperContext) -> void:
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_MACRO, {
		&"do": func (body: Array) -> Variant:
			return Lisper.Call(&"callm", [body]),
	})
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_RAW_PURE, {
		&"raw": func (_ctx: LisperContext, body: Array) -> Array:
			return body,
		&"if": func (ctx: LisperContext, body: Array) -> Variant:
			if ctx.exec_node(body[0]):
				return ctx.exec_node(body[1])
			elif body.size() > 2:
				return ctx.exec_node(body[2])
			return null,
		&"loop": func (ctx: LisperContext, body: Array) -> Variant:
			while true:
				for node in body:
					ctx.exec_node(node)
			return null,
		&"unfold": func (ctx: LisperContext, body: Array) -> Variant:
			var size := int(ctx.exec_node(body[0]))
			var handle = ctx.exec_node(body[1])
			return range(size).map(func (i): return ctx.call_fn(handle, [i])),
		&"func": func (ctx: LisperContext, body: Array) -> Array:
			var args := []
			var args_src = body[0][1]
			var idx := 0
			while idx < args_src.size():
				var node = args_src[idx]
				args.append(ctx.exec_as_keyword(node))
				idx += 1
			return [Lisper.FnType.LP_CALL, args, body.slice(1)],
		&"proc": func (ctx: LisperContext, body: Array) -> Array:
			var args := []
			var args_src = body[0][1]
			var idx := 0
			while idx < args_src.size():
				var node = args_src[idx]
				args.append(ctx.exec_as_keyword(node))
				idx += 1
			return [Lisper.FnType.LP_CALL, args, body.slice(1)],
		&"proc/call": func (ctx: LisperContext, body: Array) -> ProcedureContext:
			var vctx := ProcedureCommons.fork()
			body = body.map(ctx.exec_node)
			var handle = body[0]
			var args = body.slice(1)
			vctx.call_fn_async(handle, args)
			return vctx,
		&"array/concat": func (ctx: LisperContext, body: Array) -> Array:
			var res := []
			body = body.map(ctx.exec_node)
			for v in body:
				assert(v is Array)
				res.append_array(v)
			return res,
		&"array/map": func (ctx: LisperContext, body: Array) -> Variant:
			var ary := ctx.exec_node(body[0]) as Array
			var handle = ctx.exec_node(body[1])
			return ary.map(func (e): return ctx.call_fn(handle, [e])),
	})
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_RAW, {
		&"echo": func (ctx: LisperContext, body: Array) -> Variant:
			var msg := []
			var res
			for node in body:
				res = ctx.exec_node(node)
				msg.append(str(res))
			print(' '.join(msg))
			return res,
		&"eval": func (ctx: LisperContext, body: Array) -> Variant:
			var result = null
			for node in body:
				var res = ctx.exec_node(node)
				result = ctx.exec_node(res)
			return result,
		&"defvar": func (ctx: LisperContext, body: Array) -> void:
			var vname = body[0][1]
			if vname is String or vname is StringName:
				var data = ctx.exec_node(body[1])
				ctx.def_var([], vname, data) # TODO
			else:
				ctx.log_error(body[0], str("defvar: ", body[0], " is not a valid token")),
		&"callm": func (ctx: LisperContext, body: Array) -> Variant:
			var this := ctx.exec_node(body[0]) as Mono
			var method := ctx.exec_as_keyword(body[1]) as StringName
			var argv := ctx.exec_node(body.slice(2)) as Array
			return this.applym(method, argv),
		&"getp": func (ctx: LisperContext, body: Array) -> Variant:
			var this := ctx.exec_node(body[0]) as Mono
			var key := ctx.exec_as_keyword(body[1]) as StringName
			return this.getp(key),
		&"setp": func (ctx: LisperContext, body: Array) -> void:
			var this := ctx.exec_node(body[0]) as Mono
			var key := ctx.exec_as_keyword(body[1]) as StringName
			var value = ctx.exec_node(body[1])
			this.setp(key, value),
		&"destroy": func (ctx: LisperContext, body: Array) -> void:
			var this := ctx.exec_node(body[0]) as Mono
			this.destroy(),
		&"queue_destroy": func (ctx: LisperContext, body: Array) -> void:
			var this := ctx.exec_node(body[0]) as Mono
			this.destroy.call_deferred(),
	})
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_CALL_PURE, {
		&"vec2": func (x: float, y: float) -> Vector2:
			return Vector2(x, y),
		&"vec3": func (x: float, y: float, z: float) -> Vector3:
			return Vector3(x, y, z),
		&"rect2": func (x: float, y: float, w: float, h: float) -> Rect2:
			return Rect2(x, y, w, h),
		&"color": func (r_c = null, g_a = null, b = null, a = null) -> Color:
			if r_c == null: return Color()
			if g_a == null: return Color(r_c)
			if b == null: return Color(r_c, g_a)
			if a == null: return Color(r_c, g_a, b)
			return Color(r_c, g_a, b, a),
		&"+": func (x, y) -> Variant:
			return x + y,
		&"-": func (x, y) -> Variant:
			return x - y,
		&"*": func (x, y) -> Variant:
			return x * y,
		&"/": func (x, y) -> Variant:
			return x / y,
		&"@": func (src, ref) -> Variant:
			return src[ref],
		&"prop/setp": Prop.setp,
		&"prop/pushs": Prop.pushs,
		&"prop/puts": Prop.puts,
		&"prop/mergep": Prop.mergep,
	})
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_CALL, {
		&"debug": func (value: Variant) -> Variant:
			breakpoint
			return value,
	})
