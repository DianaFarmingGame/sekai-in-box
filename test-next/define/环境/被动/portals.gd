extends GBlockStaticExt

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Portals"
	merge_traits(sets, [TInput, TUI])
	merge_props(sets, {
		#&"act_ui": Prop.pushs([&"debug"]),
	})
	return sets
