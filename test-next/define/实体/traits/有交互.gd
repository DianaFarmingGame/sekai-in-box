class_name 有交互 extends MonoTrait

var id := &"有交互"
var requires := []

var props := {
	#
	# 配置
	#
	
	# 激活的行为 ID
	# 所有激活的行为会利用 ID 在 ready 时从 Gikou 的 DB 获取
	# 并以 0 序排列到 base 层的 action_data 内
	&"act_action": null,
	
	# 行为栈
	# 触发顺序为 layers 从上至下
	# @params: SekaiControl, src: Mono: 发起行为的原始对象, tar: Mono | null: 行为可能指向的目标对象, InputSet
	# @return: int: 触发已处理 阻止后续的行为被触发 同时代表操作消耗的精力值, null: 触发未处理
	&"action_data": Prop.Stack(),
	
	
	
	#
	# 信号
	#
	
	# 当该 Mono 的行为被触发之后被触发
	# @params: SekaiControl, src: Mono: 发起行为的原始对象, tar: Mono | null: 行为可能指向的目标对象, InputSet
	&"on_action": Prop.Stack(),
	
	
	
	#
	# 方法
	#
	
	# 触发交互行为
	# @params: SekaiControl, src: Mono: 发起行为的原始对象, tar: Mono | null: 行为可能指向的目标对象, InputSet
	# @return: int: 操作消耗的精力值, false: 触发未处理
	&"action/emit": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, src: Mono, tar: Variant, sets: InputSet) -> Variant:
		var key := &"action_data"
		var usage = null
		var lidx = 0
		for layer in this.layers:
			for entry in layer[1].get(key).duplicate():
				usage = await entry[1].call(ctx, this, ctrl, src, tar, sets)
				if usage != null: return usage
		for entry in this.getpR(key).duplicate():
			usage = await entry[1].call(ctx, this, ctrl, src, tar, sets)
			if usage != null: return usage
		return null,
	
	
	
	#--------------------------------------------------------------------------#
	&"on_ready": Prop.puts({
		&"0:有交互": func (ctx: LisperContext, this: Mono) -> void:
			var id = this.getp(&"act_action")
			if id != null:
				var handle = sekai.db.applymRSUY(ctx, &"db/get", [&"actions", id])
				if handle != null:
					this.pushsB(&"action_data", [&"0:act_action", handle]),
	}),
}
