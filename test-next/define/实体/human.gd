class_name GHuman extends GAnimal

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "人类"
	merge_traits(sets, [
		有背包, 有快捷栏, 有精力,
		可控制, 交互主体,
		UI快捷栏, UI物品栏, UI合成台, UI状态栏,
		主次行为输入,
		一般控制输入, 一般交互输入,
	])
	merge_props(sets, {
		&"pick_box": Rect2(-0.5, -1, 1, 1),
	})
	return sets
