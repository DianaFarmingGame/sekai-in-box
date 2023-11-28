class_name GTile extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_traits(sets, [TVisible])
	return super.do_merge(sets)
