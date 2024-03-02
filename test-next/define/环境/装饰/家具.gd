extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "家具"
	merge_traits(sets, [TContainer, TPickable, 有交互])
	merge_props(sets, {
		&"action_data": {
			&"primary": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, src: Mono, tar: Variant, sets: InputSet) -> Variant:
				await this.callmRSU(ctx, &"state/to", &"opened")
				await src.callmRS(ctx, &"inventory/toggle", ctrl)
				await src.applymRS(ctx, &"inventory/add", [ctrl, this])
				await src.wait(&"on_inventory_closed")
				await this.callmRSU(ctx, &"state/to", &"closed")
				return true,
		},
		&"cur_draw": &"main",
	})
	return sets
