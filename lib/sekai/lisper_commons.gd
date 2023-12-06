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
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_RAW_PURE, {
		&"raw": func (_ctx: LisperContext, body: Array) -> Array:
			return body,
		&"if": func (ctx: LisperContext, body: Array) -> Variant:
			if ctx.exec_node(body[0]):
				return ctx.exec_node(body[1])
			elif body.size() > 2:
				return ctx.exec_node(body[2])
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
		&"proc_call": func (ctx: LisperContext, body: Array) -> void:
			var vctx := ProcedureCommons.fork()
			body = body.map(ctx.exec_node)
			var handle = body[0]
			var args = body.slice(1)
			vctx.call_fn_async(handle, args),
		&"array_concat": func (ctx: LisperContext, body: Array) -> Array:
			var res := []
			body = body.map(ctx.exec_node)
			for v in body:
				assert(v is Array)
				res.append_array(v)
			return res,
	})
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_RAW, {
		&"echo": func (ctx: LisperContext, body: Array) -> void:
			var msg := []
			for node in body:
				var res = ctx.exec_node(node)
				msg.append(str(res))
			print(' '.join(msg)),
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
	})
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_CALL, {
		&"debug": func (value: Variant) -> Variant:
			breakpoint
			return value,
	})
