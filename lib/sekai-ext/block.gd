class_name GBlock extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_props(sets, {
		&"state": &"normal",
	})
	merge_traits(sets, [TVisible, TCollisible, TRoutable])
	return super.do_merge(sets)
