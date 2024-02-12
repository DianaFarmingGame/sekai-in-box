class_name GPC extends GHuman

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "PC"
	merge_traits(sets, [
		TDefTarget, UI对话框, UI选择框,
	])
	merge_props(sets, {
		&"on_action_primary": Prop.puts({
			"0:pc": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
				if pick is Mono and pick.define is GCreature:
					var val = await pick.applymRSU(ctx, &"action/emit", [ctrl, this, pick, sets])
					print(val)
				,
		}),
		&"on_action_secondary": Prop.puts({

		}),
	})
	return sets
