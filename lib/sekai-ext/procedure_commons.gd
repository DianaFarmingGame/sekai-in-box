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
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_CALL, {
		&"test": func () -> void:
			print("Say Hello to You!"),
		&"wait": func (timeout: float) -> void:
			await get_tree().create_timer(timeout).timeout,
	})
