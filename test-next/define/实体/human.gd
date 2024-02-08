class_name GHuman extends GAnimal

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "人类"
	merge_traits(sets, [
		一般控制, 有背包, 有快捷栏,
	])
	merge_props(sets, {
	})
	return sets
