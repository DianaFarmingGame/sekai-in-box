extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "箱子"
	merge_traits(sets, [TContainer, TState, TPickable, 有交互])
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
		&"cur_draw": &"closed",
		&"init_state": &"closed",
		&"state_data": {
			&"opened": {
				&"cover" : {
					&"cur_draw": &"opened",
				},
				&"on_enter": func (ctx: LisperContext, this: Mono, pre: Variant) -> void:
					this.emitmRSU(ctx, &"draw/restick"),
			},
			&"closed": {
				&"cover" : {
					&"cur_draw": &"closed",
				},
				&"on_enter": func (ctx: LisperContext, this: Mono, pre: Variant) -> void:
					this.emitmRSU(ctx, &"draw/restick"),
			},
		},
	})
	return sets
