class_name TContainer extends MonoTrait

var id := &"container"

var props := {
	&"contains": [],
	&"contains_data": [],
	&"container_capacity": INF,
	
	&"container/add": func (ctx: LisperContext, this: Mono, ref_id: Variant, opts: Dictionary = {}) -> bool:
		return await this.callm(ctx, &"container/put", sekai.make_mono(ref_id, opts)),
	&"container/put": func (ctx: LisperContext, this: Mono, item: Mono) -> bool:
		var contains := this.getpBD(&"contains", []) as Array
		if item.getp(&"stackable"):
			var putted := false
			for mono in contains:
				if mono.define.ref == item.define.ref and mono.getp(&"stackable") and await mono.callm(ctx, &"stack/put", item):
					putted = true
					break
			if putted:
				this.setpF(&"contains", contains)
				return true
		if contains.size() < this.getp(&"container_capacity"):
			contains.append(item)
			item.remove()
			item._into_container(ctx, this)
			this.setpF(&"contains", contains)
			return true
		this.setpF(&"contains", contains)
		return false,
	&"container/pick": func (ctx: LisperContext, this: Mono, item: Mono) -> Mono:
		var contains := this.getpBD(&"contains", []) as Array
		item._outof_container()
		contains.erase(item)
		this.setpF(&"contains", contains)
		return item,
	&"container/pick_by_ref_id": func (ctx: LisperContext, this: Mono, ref_id: Variant, count := 1) -> Variant:
		var type_d = sekai.get_define(ref_id)
		var contains := this.getpBD(&"contains", []) as Array
		var try_count := count
		for mono in contains:
			if try_count <= 0: break
			if mono.define.ref == type_d.ref:
				try_count -= mono.getp(&"stack/count") if mono.getp(&"stackable") else 1
		if try_count <= 0:
			var picks := []
			var removes := []
			for i in contains.size():
				var mono = contains[-(i + 1)]
				if count == 0: break
				var item = null
				if mono.define.ref == type_d.ref:
					if mono.getp(&"stackable"):
						item = await mono.callm(ctx, &"stack/try_pick", count)
						if item != null: count -= item.getp(&"stack/count")
					else:
						item = mono
						count -= 1
				if item == mono: removes.append(mono)
				if item.getp(&"stackable"):
					var putted := false
					for m in picks:
						if m.define.ref == item.define.ref and m.getp(&"stackable") and await m.callm(ctx, &"stack/put", item):
							putted = true
							break
					if putted: continue
				picks.append(item)
			for mono in removes: contains.erase(mono)
			this.setpF(&"contains", contains)
			for mono in picks: mono._outof_container()
			return picks
		return null,
	
	&"on_init": Prop.puts({
		&"0:container": func (ctx: LisperContext, this: Mono) -> void:
			var contains := this.getpBD(&"contains", []) as Array
			for mono in contains: mono.init(ctx)
			pass,
	}),
	&"on_store": Prop.puts({
		&"99:container": func (ctx: LisperContext, this: Mono) -> void:
			var contains := this.getpBD(&"contains", []) as Array
			await Async.array_map(contains, func (item): await item.store(ctx))
			var contains_data := contains.map(Mono.to_data)
			this.setp(&"contains_data", contains_data)
			pass,
	}),
	&"on_restore": Prop.puts({
		&"-99:container": func (ctx: LisperContext, this: Mono) -> void:
			var contains_data := this.getpD(&"contains_data", []) as Array
			var contains := contains_data.map(Mono.from_data)
			this.setp(&"contains", contains)
			await Async.array_map(contains, func (item): await item.restore(ctx))
			pass,
	}),
}