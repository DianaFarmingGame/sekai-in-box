class_name TContainer extends MonoTrait

# 注意: 对于实体 (GEntity), 移入容器前需要先令其退出 Sekai

var id := &"container"

var props := {
	&"contains": [],
	&"contains_data": [],
	&"container_capacity": 256,
	
	&"container_put": func (_sekai, this: Mono, item: Mono) -> bool:
		var contains := this.getpBD(&"contains", []) as Array
		if item.getp(&"stackable"):
			var putted := false
			for mono in contains:
				if mono.define.ref == item.define.ref and mono.getp(&"stackable") and await mono.callm(&"stack_put", item):
					putted = true
					break
			if putted:
				this.setpD(&"contains", await this.call_watcher(&"contains", contains, true))
				return true
		if contains.size() < this.getp(&"container_capacity"):
			contains.append(item)
			this.setpD(&"contains", await this.call_watcher(&"contains", contains, true))
			return true
		this.setpD(&"contains", await this.call_watcher(&"contains", contains, true))
		return false,
	&"container_pick": func (_sekai, this: Mono, item: Mono) -> Mono:
		var contains := this.getpBD(&"contains", []) as Array
		contains.erase(item)
		this.setpD(&"contains", await this.call_watcher(&"contains", contains, true))
		return item,
	&"container_pick_by_ref_id": func (sekai: Sekai, this: Mono, ref_id: Variant, count := 1) -> Variant:
		var type_d = sekai.get_define(ref_id)
		var contains := this.getpBD(&"contains", []) as Array
		var try_count := count
		for mono in contains:
			if try_count <= 0: break
			if mono.define.ref == type_d.ref:
				try_count -= mono.getp(&"stack_count") if mono.getp(&"stackable") else 1
		if try_count <= 0:
			var picks := []
			var removes := []
			for i in contains.size():
				var mono = contains[-(i + 1)]
				if count == 0: break
				var item = null
				if mono.define.ref == type_d.ref:
					if mono.getp(&"stackable"):
						item = await mono.callm(&"stack_try_pick", count)
						if item != null: count -= item.getp(&"stack_count")
					else:
						item = mono
						count -= 1
				if item == mono: removes.append(mono)
				if item.getp(&"stackable"):
					var putted := false
					for m in picks:
						if m.define.ref == item.define.ref and m.getp(&"stackable") and await m.callm(&"stack_put", item):
							putted = true
							break
					if putted: continue
				picks.append(item)
			for mono in removes: contains.erase(mono)
			this.setpD(&"contains", await this.call_watcher(&"contains", contains, true))
			return picks
		return null,
	&"on_store": Prop.puts({
		&"99:container": func (_sekai, this: Mono) -> void:
			var contains := this.getpBD(&"contains", []) as Array
			var contains_data := await Async.array_map(contains, func (item):
				await item._on_store()
				var script = item.get_script().resource_path
				var vdata = item.to_data()
				return [script, vdata])
			this.setp(&"contains_data", contains_data)
			pass,
	}),
	&"on_restore": Prop.puts({
		&"-99:container": func (sekai: Sekai, this: Mono) -> void:
			var contains_data := this.getpD(&"contains_data", []) as Array
			var contains := await Async.array_map(contains_data, func (data):
				var script = load(data[0])
				var vdata = data[1]
				var item = script.new()
				item.from_data(sekai, vdata)
				await item._on_restore()
				return item)
			this.setp(&"contains", contains)
			pass,
	}),
}
