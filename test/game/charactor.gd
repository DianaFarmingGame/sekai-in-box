class_name GCharactor extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_trait(sets, TVisible)
	merge_props(sets, {
		&"asserts": {},
		&"position": Vector2(0, 0),
		&"state": &"normal",
	})
	merge_methods(sets, {
		&"get_assert": func (sekai: Sekai, this, pid: StringName) -> Variant:
			return sekai.get_assert(this.get_prop(&"asserts")[pid]),
	})
	return super.do_merge(sets)
