extends "收集点.gd"

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "随机收集点"
	merge_traits(sets, [TCompile, TRandom])
	return sets
