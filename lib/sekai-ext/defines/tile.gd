class_name GTile extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GTile"
	merge_traits(sets, [TMapPosition, TAssert, TDraw])
	return sets
