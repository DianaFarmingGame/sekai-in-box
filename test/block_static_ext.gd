class_name GBlockStaticExt extends GBlockStatic

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GBlockStaticExt"
	merge_traits(sets, [TCompile, TRandom, TATile, TADestroy])
	return sets
