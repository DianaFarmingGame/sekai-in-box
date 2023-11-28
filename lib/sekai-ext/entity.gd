class_name GEntity extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_traits(sets, [TDraw])
	return super.do_merge(sets)
