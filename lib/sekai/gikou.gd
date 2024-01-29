class_name Gikou extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GiKou"
	ref = 0
	id = &"gikou"
	merge_traits(sets, [TContainer])
	merge_props(sets, {
		&"id": null,
		
		&"add_hako": func (this: Mono, pid: StringName):
			this.applym(&"container/add", [Mono, &"hako", {
				&"id": pid,
			}]),
		&"on_init": Prop.puts({
			&"-99:add_base_hako": func (this: Mono):
				this.callm(&"add_hako", &"base"),
		}),
	})
	return sets
