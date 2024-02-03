class_name Hako extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Hako"
	ref = 1
	id = &"hako"
	merge_traits(sets, [TContainer])
	merge_props(sets, {
		&"id": null,
		
		&"add_mono": func (ctx: LisperContext, this: Mono, ref_id: Variant, opts := {}) -> Mono:
			var mono := sekai.make_mono(ref_id, opts)
			this.callm(ctx, &"container/put", mono)
			return mono,
		&"collect_by_pos": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Array:
			return await this.applymRSU(ctx, &"container/collect_applyc", [&"collect_by_pos", [pos]]),
	})
	return sets
