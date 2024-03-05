extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "栅栏"
	merge_traits(sets, [TCompile, TDrawStatic, TATile])
	merge_props(sets, {
	})
	return sets
