class_name TContainer extends MonoTrait

var id := &"container"

var props := {
	&"contains": [],
	&"container_capacity": 256,
	
	&"container_put": func (_sekai, this: Mono, item: Mono) -> bool:
		var contains := this.getp(&"contains") as Array
		if item.getp(&"stackable"):
			var putted := false
			for mono in contains:
				if mono.define.ref == item.define.ref and mono.getp(&"stackable") and mono.callm(&"stack_put", item):
					putted = true
					break
			if putted: return true
		if contains.size() < this.getp(&"container_capacity"):
			contains.append(item)
			return true
		return false,
	&"container_pick": func (_sekai, this: Mono, item: Mono) -> Mono:
		var contains := this.getp(&"contains") as Array
		contains.erase(item)
		this.setp(&"contains", contains)
		return item,
	&"container_pick_by_ref": func (_sekai, this: Mono, ref: int, count := 1) -> Variant:
		var contains := this.getp(&"contains") as Array
		var try_count := count
		for mono in contains:
			if try_count <= 0: break
			if mono.define.ref == ref:
				try_count -= mono.getp(&"stack_count") if mono.getp(&"stackable") else 1
		if try_count <= 0:
			var picks := []
			var removes := []
			for i in contains.size():
				var mono = contains[-(i + 1)]
				if count == 0: break
				var item = null
				if mono.define.ref == ref:
					if mono.getp(&"stackable"):
						item = mono.callm(&"stack_try_pick", count)
						if item != null: count -= item.getp(&"stack_count")
					else:
						item = mono
						count -= 1
				if item == mono: removes.append(mono)
				if item.getp(&"stackable"):
					var putted := false
					for m in picks:
						if m.define.ref == item.define.ref and m.getp(&"stackable") and m.callm(&"stack_put", item):
							putted = true
							break
					if putted: continue
				picks.append(item)
			for mono in removes: contains.erase(mono)
			this.setp(&"contains", contains)
			return picks
		return null,
}
