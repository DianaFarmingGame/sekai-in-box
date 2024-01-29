class_name GEntity extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GEntity"
	merge_traits(sets, [TPosition, TAssert, TDraw])
	return sets
