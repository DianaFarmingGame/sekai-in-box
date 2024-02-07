class_name GMob extends GCreature

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "怪物"
	merge_traits(sets, [
		可步行, 有朝向, 绘制法_双朝向,
	])
	merge_props(sets, {
		&"state_data": {
			&"walk": {
				&"cover": {
					&"cur_draw": &"walk",
				},
				&"on_enter": func (ctx: LisperContext, this: Mono, _pres) -> void:
					await this.emitm(ctx, &"draw/reset"),
			},
		},
	})
	return sets
