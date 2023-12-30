class_name TStackable extends MonoTrait

var id := &"stackable"

var props := {
	&"stackable": true,
	&"stack_count": 1,
	&"stack_capacity": 256,
	
	&"stack_put": func (_sekai, this: Mono, item: Mono) -> bool:
		if this.define.ref == item.define.ref \
		and this.getp(&"stackable") \
		and item.getp(&"stackable"):
			var icount := item.getp(&"stack_count") as int
			var res = this.callm(&"stack_put_count", icount)
			if is_same(res, true):
				return true
			else:
				item.setp(&"stack_count", icount - res)
				return false
		return false,
	&"stack_put_count": func (_sekai, this: Mono, count = 1) -> Variant:
		if this.getp(&"stackable"):
			var cur_count := this.getp(&"stack_count") as int
			var capacity := this.getp(&"stack_capacity") as int
			if cur_count + count < capacity:
				this.setp(&"stack_count", cur_count + count)
				return true
			else:
				this.setp(&"stack_count", capacity)
				return capacity - cur_count
		return 0,
	&"stack_pick": func (_sekai, this: Mono, count = 1) -> Variant:
		if count > 0 and this.getp(&"stackable"):
			var cur_count := this.getp(&"stack_count") as int
			if cur_count > count:
				this.setp(&"stack_count", cur_count - count)
				var mono := this.clone()
				mono.setp(&"stack_count", count)
				return mono
			elif cur_count == count:
				return this
		return null,
	&"stack_try_pick": func (_sekai, this: Mono, count = 1) -> Variant:
		return this.callm(&"stack_pick", mini(count, this.getp(&"stack_count"))),
}

