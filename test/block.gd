class_name GBlock extends GTile

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	merge_traits(sets, [TCollisible, TRoutable])
	return sets
