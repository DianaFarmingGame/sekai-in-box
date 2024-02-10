class_name GHuman extends GAnimal

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "人类"
	merge_traits(sets, [
		有背包, 有快捷栏,
		可控制, 一般控制输入,
		UI快捷栏, UI物品栏,
		主次行为输入
	])
	merge_props(sets, {
	})
	return sets
