class_name GBlockStatic extends GBlock

const DEBUG_DRAW := true

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GBlockStatic"
	merge_traits(sets, [] if DEBUG_DRAW else [TDrawStatic])
	return sets
