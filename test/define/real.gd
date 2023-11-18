class_name RealDefine extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_props(sets, {
		&"position": Vector2(0, 0),
	})
	return super.do_merge(sets)
