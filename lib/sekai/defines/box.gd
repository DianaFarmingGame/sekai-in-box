class_name Box extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Box"
	merge_traits(sets, [TContainer])
	merge_props(sets, {
		&"add_mono": func (ctx: LisperContext, this: Mono, ref_id: Variant, opts := {}) -> Mono:
			var mono := sekai.make_mono(ref_id, opts)
			this.callm(ctx, &"container/put", mono)
			return mono,
		&"collect_by_pos": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Array:
			var contains := this.getpBD(&"contains", []) as Array
			var results := []
			for mono in contains:
				if AABB(Vector3(-1, -1, -0.5), Vector3(18, 18, 1)).has_point(pos - mono.position):
					var res = await mono.callmRSU(ctx, &"collect_by_pos", pos)
					if res is Array:
						results.append_array(res)
					elif res != null:
						results.append(res)
			return results,
		&"collect_by_region": func (ctx: LisperContext, this: Mono, region: AABB) -> Array:
			return await this.applymRSU(ctx, &"container/collect_applym", [&"collect_by_region", [region]]),
		&"collect_collide": func (ctx: LisperContext, this: Mono, region: Rect2, z_pos: int) -> Array:
			return await this.applymRSU(ctx, &"container/collect_applym", [&"collect_collide", [region, z_pos]]),
		&"collect_route": func (ctx: LisperContext, this: Mono, point: Vector2, z_pos: int) -> Array:
			return await this.applymRSU(ctx, &"container/collect_applym", [&"collect_route", [point, z_pos]]),
		&"collect_pick": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, cursor: Vector2) -> Array:
			return await this.applymRSU(ctx, &"container/collect_applym", [&"collect_pick", [ctrl, cursor]]),
		&"update_region": func (ctx: LisperContext, this: Mono, region: AABB) -> void:
			var monos := await this.callmRSU(ctx, &"collect_by_region", region) as Array
			for mono in monos:
				await mono.update(ctx),
		
		&"on_process": func (ctx: LisperContext, this: Mono, delta: float) -> void:
			var contains := this.getpB(&"contains") as Array
			for mono in contains:
				await (mono as Mono).callc(ctx, &"on_process", delta),
		&"on_round": func (ctx: LisperContext, this: Mono, delta: float) -> void:
			var contains := this.getpB(&"contains") as Array
			for mono in contains:
				await (mono as Mono).callc(ctx, &"on_round", delta),
	})
	return sets
