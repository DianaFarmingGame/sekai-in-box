class_name UI选择框 extends MonoTrait

var id := &"UI选择框"
var requires := [&"ui"]

var props := {
	#
	# 方法
	#
	
	# 弹出一个选择并等待其结束
	# @params: SekaiControl, {
	#	title?: String,
	#	avatar?: Texture2D,
	#	choices?: {text: String, value?: Variant = idx}[],
	# }
	&"choose_dialog/put": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, param: Dictionary) -> Variant:
		return await this.applymRSU(ctx, &"ui/oneshot", [ctrl, &"choose_dialog", param]),
	
	# 弹出一个选择并等待其结束 (GDScript 用快捷版本)
	# @params: SekaiControl, {
	#	title?: String,
	#	avatar?: Texture2D,
	# }, [String: 选项文本, Function: 选项回调 (返回值会透传)][]
	&"choose_dialog/match": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, param: Dictionary, branches := []) -> Variant:
		var choices := []
		for branch in branches:
			choices.append({&"text": branch[0]})
		param = param.duplicate()
		param[&"choices"] = choices
		var idx := await this.applymRSU(ctx, &"ui/oneshot", [ctrl, &"choose_dialog", param]) as int
		var branch := branches[idx] as Array
		if branch.size() > 1:
			return await ctx.call_fn(branch[1])
		return null,
	
	# 弹出一个选择并等待其结束 (Lisper 用快捷版本)
	# @params: SekaiControl, {
	#	title?: String,
	#	avatar?: Texture2D,
	# }, :expand :flatten [bool: 选项是否显示, String: 选项文本, Raw: 选项回调 (返回值会透传)][]
	&"choose_dialog/switch": Lisper.FnGDRaw( func (ctx: LisperContext, this: Mono, body: Array, comptime: bool) -> Variant:
		if comptime: return await ctx.compiles(body)
		var ctrl := await ctx.exec(body[0]) as SekaiControl
		var param := (await ctx.exec(body[1])).duplicate() as Dictionary
		var choices := []
		var branches := []
		for i in (body.size() - 2) / 3:
			var visible = await ctx.exec(body[3 * i + 2])
			if visible:
				var text = await ctx.exec(body[3 * i + 2 + 1])
				var branch = body[3 * i + 2 + 2]
				choices.append({&"text": text})
				branches.append(branch)
		param[&"choices"] = choices
		var idx := await this.applymRSU(ctx, &"ui/oneshot", [ctrl, &"choose_dialog", param]) as int
		return await ctx.exec(branches[idx])),
	
	
	
	#--------------------------------------------------------------------------#
	&"ui_data": {
		&"choose_dialog": preload("选择框/main.tscn"),
	},
}
