class_name Gikou extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GiKou"
	ref = 0
	id = &"gikou"
	merge_traits(sets, [TContainer])
	merge_props(sets, {
		&"id": null,
		
		&"add_hako": func (this: Mono, pid: StringName) -> void:
			this.applym(&"container/add", [&"hako", {
				&"id": pid,
			}]),
		&"get_hako": func (this: Mono, pid := &"base") -> Mono:
			var contains := this.getp(&"contains") as Array
			for hako in contains:
				if hako.getp(&"id") == pid:
					return hako
			return null,
		&"on_init": Prop.puts({
			&"-99:add_base_hako": func (this: Mono) -> void:
				this.callm(&"add_hako", &"base"),
		}),
	})
	return sets
