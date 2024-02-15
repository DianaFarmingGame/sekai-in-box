extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "箱子"
	merge_traits(sets, [TContainer, TPickable, 有交互])
	merge_props(sets, {
		&"action_data": {
			&"primary": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, src: Mono, tar: Variant, sets: InputSet) -> Variant:
				await src.applymRS(ctx, &"ui/toggle", [ctrl, &"inventory"])
				await src.applymRS(ctx, &"inventory/open", [ctrl, this])
				return true,
		}
	})
	return sets
