class_name Hako extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Hako"
	ref = 1
	id = &"hako"
	merge_traits(sets, [TContainer])
	return sets
