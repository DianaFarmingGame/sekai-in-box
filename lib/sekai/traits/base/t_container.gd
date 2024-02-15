class_name TContainer extends MonoTrait

var id := &"container"

var props := {
	#
	# 配置
	#
	
	# 物品栏内包含的物品, 可以是 ref_id, 会在初始化时被自动转化
	&"contains": [],
	
	# 物品栏的容量, 和堆叠数量无关
	&"container_capacity": INF,
	
	
	
	#
	# 信号
	#
	
	# 当物品栏发生改变时触发
	&"on_contains_mod": Prop.Stack(),
	
	
	
	#
	# 方法
	#
	
	&"container/add": func (ctx: LisperContext, this: Mono, ref_id: Variant, opts: Dictionary = {}) -> bool:
		return await this.callm(ctx, &"container/put", sekai.make_mono(ref_id, opts)),
	&"container/put": func (ctx: LisperContext, this: Mono, item: Mono) -> bool:
		var contains := this.getpBD(&"contains", []) as Array
		if item.getp(&"can_stack"):
			var putted := false
			for mono in contains:
				if mono.define.ref == item.define.ref and mono.getp(&"can_stack") and await mono.callm(ctx, &"stack/put", item):
					putted = true
					break
			if putted:
				this.setpF(ctx, &"contains", contains)
				return true
		if contains.size() < this.getp(&"container_capacity"):
			contains.append(item)
			item.remove(ctx)
			this.setpF(ctx, &"contains", contains)
			await item._into_container(ctx, this)
			return true
		this.setpF(ctx, &"contains", contains)
		return false,
	&"container/count_by_ref_id": func (ctx: LisperContext, this: Mono, ref_id: Variant) -> int:
		var ref = sekai.get_define(ref_id).ref
		var contains := this.getpBR(&"contains") as Array
		var count := 0
		for mono in contains:
			if mono.define.ref == ref:
				count += mono.getp(&"stack/count") if mono.getp(&"can_stack") else 1
		return count,
	&"container/get_by_ref_id": func (ctx: LisperContext, this: Mono, ref_id: Variant) -> Variant:
		var ref = sekai.get_define(ref_id).ref
		var contains := this.getpBD(&"contains", []) as Array
		for mono in contains:
			if mono.define.ref == ref:
				return mono
		return null,
	&"container/pick": func (ctx: LisperContext, this: Mono, item: Mono) -> Mono:
		var contains := this.getpBD(&"contains", []) as Array
		item._outof_container()
		contains.erase(item)
		this.setpF(ctx, &"contains", contains)
		return item,
	&"container/pick_by_ref_id": func (ctx: LisperContext, this: Mono, ref_id: Variant, count := 1) -> Variant:
		var ref = sekai.get_define(ref_id).ref
		var contains := this.getpBD(&"contains", []) as Array
		var try_count := count
		for mono in contains:
			if try_count <= 0: break
			if mono.define.ref == ref:
				try_count -= mono.getp(&"stack/count") if mono.getp(&"can_stack") else 1
		if try_count <= 0:
			var picks := []
			var removes := []
			for i in contains.size():
				var mono = contains[-(i + 1)]
				if count == 0: break
				var item = null
				if mono.define.ref == ref:
					if mono.getp(&"can_stack"):
						item = await mono.callm(ctx, &"stack/try_pick", count)
						if item != null: count -= item.getp(&"stack/count")
					else:
						item = mono
						count -= 1
				if item == mono: removes.append(mono)
				if item.getp(&"can_stack"):
					var putted := false
					for m in picks:
						if m.define.ref == item.define.ref and m.getp(&"can_stack") and await m.callm(ctx, &"stack/put", item):
							putted = true
							break
					if putted: continue
				picks.append(item)
			for mono in removes: contains.erase(mono)
			this.setpF(ctx, &"contains", contains)
			for mono in picks: mono._outof_container()
			return picks
		return null,
	&"container/collect_applyc": func (ctx: LisperContext, this: Mono, key: StringName, argv: Array) -> Array:
		var contains := this.getpBD(&"contains", []) as Array
		var results := []
		for mono in contains:
			var res = await (mono as Mono).applyc(ctx, key, argv)
			if res is Array:
				results.append_array(res)
			elif res != null:
				results.append(res)
		return results,
	
	
	
	#--------------------------------------------------------------------------#
	&"contains_data": [],
	&"on_init": Prop.puts({
		&"0:container": func (ctx: LisperContext, this: Mono) -> void:
			var contains := this.getpBD(&"contains", []) as Array
			for i in contains.size():
				var mono = contains[i]
				if not mono is Mono:
					contains[i] = sekai.make_mono(mono),
	}),
	&"on_store": Prop.puts({
		&"99:container": func (ctx: LisperContext, this: Mono) -> void:
			var contains := this.getpBD(&"contains", []) as Array
			var contains_data := await Async.array_map(contains, func (item): return await Mono.store_to_data(ctx, item))
			this.setpB(&"contains_data", contains_data)
			this.setpB(&"contains", [])
			pass,
	}),
	&"on_restore": Prop.puts({
		&"-99:container": func (ctx: LisperContext, this: Mono) -> void:
			var contains_data := this.getpD(&"contains_data", []) as Array
			var contains := contains_data.map(Mono.from_data)
			contains.map(func (mono): mono.root = this)
			this.setpB(&"contains", contains)
			this.setpB(&"contains_data", [])
			await Async.array_map(contains, func (item): await item.restore(ctx))
			pass,
	}),
	&"on_ready": Prop.puts({
		&"-99:container": func (ctx: LisperContext, this: Mono) -> void:
			var contains := this.getpBD(&"contains", []) as Array
			await Async.array_map(contains, func (item): await item._into_container(ctx, this)),
	}),
	&"after_contains": Prop.Stack({
		&"0:container": func (ctx: LisperContext, this: Mono, contains: Array) -> void:
			this.emitc(ctx, &"on_contains_mod"),
	})
}
