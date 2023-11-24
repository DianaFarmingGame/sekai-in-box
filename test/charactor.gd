class_name GCharactor extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_traits(sets, [TVisible, TInputKey])
	merge_props(sets, {
		&"position": Vector2(0, 0),
		&"state": &"normal",
	})
	merge_methods(sets, {
		
	})
	return super.do_merge(sets)
