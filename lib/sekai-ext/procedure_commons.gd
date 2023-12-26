extends Node

var CommonContext: ProcedureContext

func eval(expr: String) -> Variant:
	var ctx := CommonContext.fork()
	var res = ctx.eval(expr)
	return [ctx, res]

func fork() -> ProcedureContext:
	return CommonContext.fork()

func clone() -> ProcedureContext:
	return CommonContext.clone()

func _init() -> void:
	CommonContext = ProcedureContext.new()
	LisperCommons.def_commons(CommonContext)
	def_commons(CommonContext)

func def_commons(ctx: ProcedureContext) -> void:
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_RAW_PURE, {
		&"if": func (ctx: LisperContext, body: Array) -> Variant:
			if await ctx.exec_node_async(body[0]):
				return await ctx.exec_node_async(body[1])
			elif body.size() > 2:
				return await ctx.exec_node_async(body[2])
			return null,
		&"loop": func (ctx: LisperContext, body: Array) -> Variant:
			while true:
				for node in body:
					await ctx.exec_node_async(node)
			return null,
	})
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_RAW, {
		&"callm": func (ctx: ProcedureContext, body: Array) -> Variant:
			var this := await ctx.exec_node_async(body[0]) as Mono
			var method := ctx.exec_as_keyword(body[1]) as StringName
			var them := await ctx.exec_async(body.slice(2)) as Array
			return await this.applymA(method, them),
		&"go": func (ctx: ProcedureContext, body: Array) -> void:
			for node in body:
				ctx.exec_node_async(node)
			pass,
	})
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_CALL, {
		&"delay": func (timeout: float) -> void:
			await get_tree().create_timer(timeout).timeout,
	})
