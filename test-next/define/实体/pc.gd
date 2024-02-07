class_name GPC extends GHuman

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "PC"
	merge_traits(sets, [
		TDefTarget,
	])
	merge_props(sets, {
	})
	return sets
