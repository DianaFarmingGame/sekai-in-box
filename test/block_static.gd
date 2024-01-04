class_name GBlockStatic extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GBlockStatic"
	merge_traits(sets, [TDrawStatic])
	return sets
