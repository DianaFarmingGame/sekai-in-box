class_name GBlockStaticExt extends GBlockStatic

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	merge_traits(sets, [TGroup, TRandom, TATile])
	return sets
