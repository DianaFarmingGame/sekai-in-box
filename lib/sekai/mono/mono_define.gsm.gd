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
		&"on_init": Prop.Stack(),
		&"on_inited": Prop.Stack(),
		&"on_store": Prop.Stack(),
		&"on_restore": Prop.Stack(),
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
