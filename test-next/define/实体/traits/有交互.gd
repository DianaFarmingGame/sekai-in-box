class_name 有交互 extends MonoTrait

var id := &"有交互"

var props := {
	#
	# 配置
	#
	
	# 行为表
	# 触发顺序为 layers 从上至下
	# @params:
	#		SekaiControl,
	#		src: Mono: 发起行为的原始对象,
	#		tar: Mono | null: 行为可能指向的目标对象,
	#		InputSet,
	# @return: true: 操作成功, null: 触发未处理
	&"action_data": {},
	
	
	
	#
	# 信号
	#
	
	# 当该 Mono 的行为被触发之后被触发
	# @params:
	#		type: StringName,
	#		SekaiControl,
	#		src: Mono: 发起行为的原始对象,
	#		tar: Mono | null: 行为可能指向的目标对象,
	#		InputSet
	&"on_action": {

	},
	
	
	
	#
	# 方法
	#
	
	# 设置一个行为
	# @params: type: StringName: 行为的类型, handle: Function: 要设置的行为回调 | null: 删除这个行为
	&"action/set": func (ctx: LisperContext, this: Mono, type: StringName, handle: Variant) -> void:
		var data := this.getpBD(&"action_data", {}) as Dictionary
		if handle != null:
			data[type] = handle
		else:
			data.erase(type)
		this.setpB(&"action_data", data),
	
	# 触发交互行为
	# @params:
	#		type: StringName,
	#		SekaiControl,
	#		src: Mono: 发起行为的原始对象,
	#		tar: Mono | null: 行为可能指向的目标对象,
	#		InputSet,
	# @return: true: 操作成功 | null: 触发未处理
	&"action/emit": func (ctx: LisperContext, this: Mono, type: StringName, ctrl: SekaiControl, src: Mono, tar: Variant, sets: InputSet) -> Variant:
		var key := &"action_data"
		var usage = null
		for layer in this.layers:
			var handle = layer[1].get(key, {}).get(type)
			if handle != null:
				if not Lisper.is_fn(handle): handle = sekai.db.applymRSUY(ctx, &"db/get", [handle, &"actions"])
				usage = await ctx.call_method(this, handle, [ctrl, src, tar, sets])
				if usage != null:
					await this.applyc(ctx, &"on_action", [type, ctrl, src, tar, sets])
					return usage
		var handle = this.getpRD(key, {}).get(type)
		if handle != null:
			if not Lisper.is_fn(handle): handle = sekai.db.applymRSUY(ctx, &"db/get", [handle, &"actions"])
			if handle != null:
				usage = await ctx.call_method(this, handle, [ctrl, src, tar, sets])
				if usage != null:
					await this.applyc(ctx, &"on_action", [type, ctrl, src, tar, sets])
					return usage
		return null,
	
	# 跳转交互
	# @params:
	#		id: StringName,
	#		SekaiControl,
	#		src: Mono: 发起行为的原始对象,
	#		tar: Mono | null: 行为可能指向的目标对象,
	#		InputSet,
	# @return true
	&"action/call": func (ctx: LisperContext, this: Mono, id: StringName, ctrl: SekaiControl, src: Mono, tar: Variant, sets: InputSet) -> int:
		var handle = sekai.db.applymRSUY(ctx, &"db/get", [id, &"actions"])
		await ctx.call_method(this, handle, [ctrl, src, tar, sets])
		return true,
	
	
	
	#--------------------------------------------------------------------------#

	&"on_ready": Prop.puts({
		&"-99:set_db_val": func (ctx: LisperContext, this: Mono) -> void:
			var action_data = this.getpBD(&"action_data", {})
			for key in action_data:
				if not sekai.gikou.callmRSUY(ctx, &"db/has", [key, &"vals"]):
					sekai.gikou.applymRSUY(ctx, &"db/set", [key, 0, &"vals"])
			,
	},)
}
