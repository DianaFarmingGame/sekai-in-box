class_name GNPC extends GHuman

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "NPC"
	merge_traits(sets, [])
	merge_props(sets, {
	})
	return sets
