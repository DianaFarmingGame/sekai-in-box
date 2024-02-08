class_name Hako extends Box

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Hako"
	ref = 1
	id = &"hako"
	merge_props(sets, {
		&"id": null,
		&"active_level": 0,
	})
	return sets
