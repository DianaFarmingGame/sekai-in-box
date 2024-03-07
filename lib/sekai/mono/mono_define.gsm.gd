class_name MonoDefine extends TraitLike

static func get_define(define: Variant) -> MonoDefine:
	if not define is MonoDefine: define = define.new()
	return define 

@export var ref: int
@export var id: StringName
@export var name: String
@export var traits: Array[TraitLike]
@export var props: Dictionary

func _get_name() -> StringName:
	return str(ref, ":", id, "(", name, ")")

func _get_own_traits() -> Array[TraitLike]:
	return traits

func _get_own_props() -> Dictionary:
	return props

func _do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	sets = do_merge(sets)
	sets = merge_traits(sets, _get_own_traits())
	sets = merge_props(sets, _get_own_props())
	return sets

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	name = "MonoDefine"
	merge_props(sets, {
		# 当第一次进入 Gikou 时触发
		&"on_init": Prop.Stack(),
		# 当生成结束时被触发
		&"on_inited": Prop.Stack(),
		# 当被存储时触发
		&"on_store": Prop.Stack(),
		# 当从存储状态中恢复时触发
		&"on_restore": Prop.Stack(),
		# 当每次恢复或生成结束时触发
		&"on_ready": Prop.Stack(),
		# 当临近方块更新时触发
		&"on_update": Prop.Stack(),
		# 当经过一轮（如一天）时触发
		&"on_round": Prop.Stack(),
		
		# 当任意使用 Setter 的属性被修改时触发
		# @params: StringName: 被修改的键, Variant: 被修改的值
		&"on_mod": Prop.Stack(),
		
		# 当进入任意 SekaiControl 时触发
		# @params: SekaiControl: 触发的节点
		&"on_control_enter": Prop.Stack({
			#&"0:base": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
				#prints(this, "entered", ctrl),
		}),
		
		# 当离开任意 SekaiControl 时触发
		# @params: SekaiControl: 触发的节点
		&"on_control_exit": Prop.Stack({
			#&"0:base": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
				#prints(this, "exited", ctrl),
		}),
		
		# 当成为某个 SekaiControl 的 target 时触发
		# @params: SekaiControl: 触发的节点
		&"on_target_set": Prop.Stack(),
		# 取消成为某个 SekaiControl 的 target 时触发
		# @params: SekaiControl: 触发的节点
		&"on_target_unset": Prop.Stack(),
	})
	return sets



func gsm(): return ['

defunc (define/make :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime:
			var cdata := [await ctx.compile(body[0])]
			cdata.append_array(await LisperCommons.compile_map(ctx, body.slice(1)))
			return cdata
		var def = await ctx.exec(body[0])
		if def != null:
			def = MonoDefine.get_define(def).fork()
			var args = await ctx.exec_map_part(body.slice(1))
			for k in args.keys():
				match k:
					&"props":
						def.do_override_props(args[k])
					_:
						def.set(k, args[k])
			return def
		else:
			await ctx.log_error(body[0], str("define/make: ", body[0], " is not a valid token"))
			return null
,')

']
