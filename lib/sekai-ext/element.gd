class_name GElement extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GElement"
	merge_traits(sets, [TAssert])
	return sets
