class_name Hako extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Hako"
	ref = 1
	id = &"hako"
	merge_traits(sets, [TContainer])
	merge_props(sets, {
		&"id": null,
		
		&"add_mono": func (this: Mono, ref_id: Variant, opts := {}) -> Mono:
			var mono := sekai.make_mono(ref_id, opts)
			this.callm(&"container/put", mono)
			return mono,
	})
	return sets
