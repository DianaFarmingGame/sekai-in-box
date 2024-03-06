extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "建筑物"
	merge_traits(sets, [TPickable])
	return sets
