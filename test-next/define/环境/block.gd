class_name GBlock extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GBlock"
	merge_traits(sets, [TGroup, TCollisible])
	return sets
