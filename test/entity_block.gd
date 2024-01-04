class_name GEntityBlock extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GEntityBlock"
	merge_traits(sets, [TGroup, TCollisible])
	return sets
