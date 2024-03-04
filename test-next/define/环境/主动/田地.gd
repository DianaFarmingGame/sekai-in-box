extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "田地"
	merge_traits(sets, [TCompile, TATile])
	return sets
