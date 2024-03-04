extends GBlock

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "随机装饰面"
	merge_traits(sets, [TCompile, TDrawStatic, TATile, TRandom])
	merge_props(sets, {
		&"need_collision": false,
		&"can_collide": false,
	})
	return sets
