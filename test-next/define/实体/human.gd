class_name GHuman extends GAnimal

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "人类"
	merge_traits(sets, [])
	merge_props(sets, {
	})
	return sets
