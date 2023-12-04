class_name GBlockStaticATile extends GBlockStatic

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	merge_traits(sets, [TATile])
	return sets
