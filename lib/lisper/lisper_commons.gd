class_name LisperCommons

static func make_common_context(pname = null) -> LisperContext:
	var context := LisperContext.make(pname)
	await def_commons(context)
	return context

static func compile_block(ctx: LisperContext, body: Array) -> Array:
	body = await ctx.compiles(body)
	var res = body[-1]
	var tbody := body.slice(0, -1).filter(func (n): return not Lisper.is_raw(n))
	if tbody.size() == 0:
		return Lisper.RawOverride(res)
	tbody.append(res)
	return tbody

static func compile_map(ctx: LisperContext, body: Array) -> Array:
	var cdata := []
	var is_key := true
	for n in body:
		if is_key:
			cdata.append(Lisper.Raw(await ctx.exec_as_keyword(n)))
		else:
			cdata.append(await ctx.compile(n))
		is_key = not is_key
	return cdata

static func compile_keyword_mask_1(ctx: LisperContext, body: Array) -> Array:
	var cdata := []
	var cid := 0
	for n in body:
		if Lisper.is_flag(n): cdata.append(n); continue
		if cid == 0: cdata.append(Lisper.Raw(await ctx.exec_as_keyword(n)))
		else: cdata.append(await ctx.compile(n))
		cid += 1
	return cdata

static func compile_keyword_mask_01(ctx: LisperContext, body: Array) -> Array:
	var cdata := []
	var cid := 0
	for n in body:
		if Lisper.is_flag(n): cdata.append(n); continue
		if cid == 0: cdata.append(await ctx.compile(n))
		elif cid == 1: cdata.append(Lisper.Raw(await ctx.exec_as_keyword(n)))
		else: cdata.append(await ctx.compile(n))
		cid += 1
	return cdata

static func _parse_func(ctx: LisperContext, body: Array) -> Lisper.Function:
	var res := ctx.strip_flags(body)
	var flags := res[0] as Array
	body = res[1]
	if flags.has(&":gd"):
		var node := body[0] as Array
		if Lisper.is_raw(node):
			var handle = node[1]
			if flags.has(&":raw"):
				return Lisper.FnGDRaw(handle)
			if flags.has(&":macro"):
				return Lisper.FnGDMacro(handle)
			if flags.has(&":apply"):
				if flags.has(&":pure"):
					return Lisper.FnGDApplyP(handle)
				else:
					return Lisper.FnGDApply(handle)
			if flags.has(&":pure"):
				return Lisper.FnGDCallP(handle)
			else:
				return Lisper.FnGDCall(handle)
		else:
			push_error("failed to get handle")
			printerr("failed to get handle")
			printerr("node: ", ctx.stringify(node))
			printerr("@: ", ctx.stringifys(body))
			return Lisper.Function.new()
	else:
		var args := await Async.array_map(body[0][1], ctx.exec_as_keyword)
		var tbody := await ctx.compiles(body.slice(1))
		if flags.has(&":pure"):
			return Lisper.FnLPCallP(args, tbody)
		return Lisper.FnLPCall(args, tbody)

static func def_commons(context: LisperContext) -> void:
	context.def_consts({
		&"exec": Lisper.FnGDApply( func (ctx: LisperContext, args: Array) -> void:
			var mod_dir = ctx.get_var(&"*mod-dir*")
			var path := args[0] as String
			if path.is_relative_path() and mod_dir != null:
				path = (mod_dir as String).path_join(path)
			await Lisper.exec(ctx, path)),
		&"!break": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await ctx.compiles(body)
			var vname := "!::" + str(await ctx.exec(body[0])) if body.size() > 0 else "!::break"
			await ctx.trigger_break(vname)
			return null),
		&"!debug": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await ctx.compiles(body)
			var vname := "!::debug"
			await ctx.trigger_break(vname)
			return (await ctx.execs(body))[-1]),
		&"defvar": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await compile_keyword_mask_1(ctx, body)
			var res := ctx.strip_flags(body)
			var flags: Array[Lisper.VarFlag] = []
			for f in res[0]:
				match f:
					&":const": flags.append(Lisper.VarFlag.CONST)
					&":fix": flags.append(Lisper.VarFlag.FIX)
			body = res[1]
			var vname = await ctx.exec_as_keyword(body[0])
			await ctx.test(vname is StringName, "failed to parse var name")
			var data = await ctx.exec(body[1])
			ctx.def_var(flags, vname, data)
			return null),
		&"setvar": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await compile_keyword_mask_1(ctx, body)
			else:
				var vname := await ctx.exec_as_keyword(body[0]) as StringName
				var data = await ctx.exec(body[1])
				ctx.set_var(vname, data)
				return null),
		&"defunc": Lisper.FnGDMacro( func (ctx: LisperContext, body: Array) -> Array:
			var res := ctx.strip_flags(body)
			var var_flags := []
			var fn_flags := []
			for f in res[0]:
				match f:
					&":const", &":fix": var_flags.append(f)
					&":pure", &":gd", &":raw", &":macro", &":apply": fn_flags.append(f)
			body = res[1]
			return Lisper.apply(&"defvar", [var_flags.map(Lisper.Token), [
				body[0],
				Lisper.apply(&"func", [fn_flags.map(Lisper.Token), body.slice(1)]),
			]])),
		&"func": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return body
			return await _parse_func(ctx, body)),
		&"factor": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			var handle := await _parse_func(ctx, body)
			if comptime: return Lisper.RawOverride(Lisper.Raw(handle))
			return handle),
		&"remember": Lisper.FnGDApplyP( func (ctx: LisperContext, args: Array) -> Variant:
			var target = args[0]
			ctx.remembers.append(args)
			return target),
	})
	await Lisper.exec(context, "res://lib/lisper/std/commons.gss.txt")
