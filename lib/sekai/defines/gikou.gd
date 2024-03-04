class_name Gikou extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Gikou"
	ref = 0
	id = &"gikou"
	merge_traits(sets, [TContainer, TDatabase, TKVContainer, TTaskManager, TDBVal])
	merge_props(sets, {
		&"id": null,
		&"def_target": null,
		&"uid_data": {},
		
		&"add_hako": func (ctx: LisperContext, this: Mono, pid: StringName) -> void:
			this.applym(ctx, &"container/add", [&"hako", {
				&"id": pid,
			}]),
		&"get_hako": func (ctx: LisperContext, this: Mono, pid := &"base") -> Mono:
			var contains := this.getpB(&"contains") as Array
			for hako in contains:
				if hako.getp(&"id") == pid:
					return hako
			return null,
		&"set_uid": func (ctx: LisperContext, this: Mono, uid: StringName, item: Mono) -> void:
			var data := this.getpBD(&"uid_data", {}) as Dictionary
			data[uid] = item
			this.setpB(&"uid_data", data),
		&"get_uid": func (ctx: LisperContext, this: Mono, uid: StringName) -> Mono:
			var data := this.getpBD(&"uid_data", {}) as Dictionary
			var item = data.get(uid)
			if item != null:
				return item
			else:
				return null,
		
		&"on_init": Prop.puts({
			&"-99:add_base_hako": func (ctx: LisperContext, this: Mono) -> void:
				await this.callm(ctx, &"add_hako", &"base"),
		}),
	})
	return sets
