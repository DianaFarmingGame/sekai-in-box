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

func def_commons(context: ProcedureContext) -> void:
	context.def_vars([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], {
		&"block": Lisper.FuncGDRawPure( func (ctx: ProcedureContext, body: Array) -> Variant:
			return (await ctx.exec_async(body))[-1] if body.size() > 0 else null),
		&"if": Lisper.FuncGDRawPure( func (ctx: ProcedureContext, body: Array) -> Variant:
			if await ctx.exec_node_async(body[0]):
				return await ctx.exec_node_async(body[1])
			elif body.size() > 2:
				return await ctx.exec_node_async(body[2])
			return null),
		&"loop": Lisper.FuncGDRawPure( func (ctx: ProcedureContext, body: Array) -> Variant:
			while true:
				for node in body:
					await ctx.exec_node_async(node)
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
					await ctx.exec_node_async(node)
			return res[0]),
		&"do": Lisper.FuncGDRaw( func (ctx: ProcedureContext, body: Array) -> Variant:
			var this := await ctx.exec_node_async(body[0]) as Mono
			var act_name := ctx.exec_as_keyword(body[1]) as StringName
			var action = this.getp(&"actions").get(act_name)
			if action == null: action = this.getpR(&"actions").get(act_name)
			var argv := [Lisper.Raw(this.sekai), Lisper.Raw(this)]
			argv.append_array(body.slice(2))
			return await ctx.call_rawfn_async(action, argv)),
		&"callm": Lisper.FuncGDRaw( func (ctx: ProcedureContext, body: Array) -> Variant:
			var this := await ctx.exec_node_async(body[0]) as Mono
			var method := ctx.exec_as_keyword(body[1]) as StringName
			var them := await ctx.exec_async(body.slice(2)) as Array
			return await this.applymA(method, them)),
		&"go": Lisper.FuncGDRaw( func (ctx: ProcedureContext, body: Array) -> void:
			for node in body:
				ctx.exec_node_async(node)
			pass),
		&"delay": Lisper.FuncGDCall( func (timeout: float) -> void:
			await get_tree().create_timer(timeout).timeout),
		&"echo": Lisper.FuncGDRaw( func (ctx: ProcedureContext, body: Array) -> Variant:
			var msg := []
			var res
			for node in body:
				res = await ctx.exec_node_async(node)
				msg.append(str(res))
			print(' '.join(msg))
			return res),
	})
