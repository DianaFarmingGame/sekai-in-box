extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "生长物"
	merge_traits(sets, [TState, 可生长])
	return sets
