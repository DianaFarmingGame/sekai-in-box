class_name GBlockStatic extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_props(sets, {
		&"state": &"normal",
	})
	merge_traits(sets, [TDrawStatic])
	return super.do_merge(sets)
