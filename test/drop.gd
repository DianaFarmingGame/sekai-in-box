class_name GDrop extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GDrop"
	merge_traits(sets, [TSolid, TProcess, TContainer])
	merge_props(sets, {
	})
	return sets
