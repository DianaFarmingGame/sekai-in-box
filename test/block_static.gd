class_name GBlockStatic extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GBlockStatic"
	merge_traits(sets, [] if ProjectSettings.get_setting(&"global/debug_draw") else [TDrawStatic])
	return sets
