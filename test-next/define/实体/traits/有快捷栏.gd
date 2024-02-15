class_name 有快捷栏 extends MonoTrait

var id := &"有快捷栏"
var requires := [&"有背包"]

var props := {
	#
	# 配置
	#
	
	# 快捷栏的数量
	&"slot_size": 5,
	
	# 快捷栏映射的物品 ref_id
	# 不需要数量相等，但超出快捷栏大小的部分会被截断
	&"slot_data": Prop.Stack(),
	
	# 当前的快捷栏位置
	&"cur_slot": 1,
	
	
	
	#
	# 信号
	#
	
	# 当快捷栏的获取内容改变时触发
	&"on_slots_mod": Prop.Stack(),
	
	# 当前的快捷栏位置改变时触发
	&"on_cur_slot_mod": Prop.Stack(),
	
	
	
	#
	# 方法
	#
	
	# 设置快捷栏
	# @params: int: 要设置的快捷栏位置, Mono | MonoDefine | ref_id | null: 要设置的物品 (null 为清除)
	&"slot/set": func (ctx: LisperContext, this: Mono, slot: int, item: Variant) -> void:
		var data := this.getp(&"slot_data").duplicate() as Array
		var ref
		if item == null:
			ref = null
		elif item is Mono:
			ref = item.define.ref
		elif item is MonoDefine:
			ref = item.ref
		else:
			ref = sekai.get_define(item).ref
		data[slot] = ref
		await this.setpBW(ctx, &"slot_data", data),
	
	# 设置当前选择的快捷栏
	# @params: Mono | MonoDefine | ref_id | null: 要设置的物品 (null 为清除)
	&"slot/set_current": func (ctx: LisperContext, this: Mono, item: Variant) -> void:
		var cur := this.getp(&"cur_slot") as int
		await this.applymRSU(ctx, &"slot/set", [cur, item]),
	
	# 移动快捷栏的选择位置
	# @params: int: 移动的偏移
	&"slot/move": func (ctx: LisperContext, this: Mono, offset: int) -> void:
		var size := this.getp(&"slot_size") as int
		var cur := this.getp(&"cur_slot") as int
		cur = wrapi(cur + offset, 0, size)
		await this.setpBW(ctx, &"cur_slot", cur),
	
	# 获取某个快捷栏的物品 (非取出)
	# @params: int: 要获取的快捷栏位置
	# @return: Mono | null
	&"slot/get": func (ctx: LisperContext, this: Mono, slot: int) -> Variant:
		var data := this.getp(&"slot_data") as Array
		var ref = data[slot]
		if ref != null:
			return this.callmRSUY(ctx, &"container/get_by_ref_id", ref)
		return null,
	
	# 获取当前选择的快捷栏的物品 (非取出)
	# @params: void
	# @return: Mono | null
	&"slot/get_current": func (ctx: LisperContext, this: Mono) -> Variant:
		var cur := this.getp(&"cur_slot") as int
		return this.callmRSUY(ctx, &"slot/get", cur),
	
	# 获取当前快捷栏的所有物品 (非取出)
	# @params: void
	# @return: (Mono | null)[]
	&"slot/get_all": func (ctx: LisperContext, this: Mono) -> Variant:
		var data := this.getp(&"slot_data") as Array
		return data.map(func (ref): return this.callmRSUY(ctx, &"container/get_by_ref_id", ref) if ref != null else null),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_init": Prop.puts({
		&"0:有快捷栏": func (ctx: LisperContext, this: Mono) -> void:
			var data := this.getp(&"slot_data") as Array
			var size := this.getp(&"slot_size") as int
			data.resize(size)
			this.setpB(&"slot_data", data),
	}),
	&"after_cur_slot": Prop.Stack({
		&"0:有快捷栏": func (ctx: LisperContext, this: Mono, slot: int) -> void:
			this.emitc(ctx, &"on_cur_slot_mod"),
	}),
	&"after_slot_data": Prop.Stack({
		&"0:有快捷栏": func (ctx: LisperContext, this: Mono, data: Array) -> void:
			this.emitc(ctx, &"on_slots_mod"),
	}),
	&"on_contains_mod": Prop.puts({
		&"0:有快捷栏": func (ctx: LisperContext, this: Mono, contains: Array) -> void:
			this.emitc(ctx, &"on_slots_mod"),
	}),
}
