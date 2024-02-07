class_name GDatabase extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GDatabase"
	merge_traits(sets, [TDatabase])
	return sets
