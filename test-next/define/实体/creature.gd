class_name GCreature extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "生物"
	merge_traits(sets, [
		TInput, TProcess, TState, TUI,
		TSolid, TPickable, TContactable,
		TMove, TPick,
	])
	merge_props(sets, {
		&"name": "UMA",
		&"solid_route_zoffset": -1,
		&"init_state": &"idle",
		&"state_data": {
			&"idle": {
				&"cover": {
					&"cur_draw": &"idle",
				},
				&"on_enter": func (ctx: LisperContext, this: Mono, _pres) -> void:
					await this.emitm(ctx, &"draw/reset"),
			},
		},
	})
	return sets
