class_name GBlock extends GTile

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_props(sets, {
		&"state": &"normal",
	})
	merge_traits(sets, [TCollisible, TRoutable])
	return super.do_merge(sets)
