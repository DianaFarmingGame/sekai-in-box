class_name Gikou extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GiKou"
	ref = 0
	id = &"gikou"
	merge_traits(sets, [TContainer])
	merge_props(sets, {
		&"id": null,
		&"def_target": null,
		
		&"add_hako": func (ctx: LisperContext, this: Mono, pid: StringName) -> void:
			this.applym(ctx, &"container/add", [&"hako", {
				&"id": pid,
			}]),
		&"get_hako": func (ctx: LisperContext, this: Mono, pid := &"base") -> Mono:
			var contains := this.getpB(&"contains") as Array
			for hako in contains:
				if hako.getp(&"id") == pid:
					return hako
			return null,
		
		&"on_init": Prop.puts({
			&"-99:add_base_hako": func (ctx: LisperContext, this: Mono) -> void:
				await this.callm(ctx, &"add_hako", &"base"),
		}),
	})
	return sets
