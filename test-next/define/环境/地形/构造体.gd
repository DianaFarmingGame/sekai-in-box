extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "构造体"
	merge_traits(sets, [TRoutable, TCompile, TDrawStatic, TATile])
	return sets
