class_name GBlockStatic extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	merge_traits(sets, [TDrawStatic])
	merge_props(sets, {
		&"state": &"normal",
	})
	return sets
