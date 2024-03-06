extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "收集点"
	merge_traits(sets, [TPickable])
	return sets
