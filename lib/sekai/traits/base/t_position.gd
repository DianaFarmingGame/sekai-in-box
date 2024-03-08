class_name TPosition extends MonoTrait

var id := &"position"

var props := {
	#
	# 配置
	#
	
	# 设置初始位置 (仅在 init 之前有效)
	&"position": null,
	
	# 历史遗留参数, 现用于配置 TATile 的扫描单元格大小
	&"size": Vector3(1, 1, 1),
	
	
	
	#
	# 方法
	#
	
	# 设置位置
	# @params: Vector3|Vector2:
	#				目标位置
	#				如果为 Vector2 则 Z 轴保持不变
	&"position/set": func (ctx: LisperContext, this: Mono, pos: Variant) -> void:
		if not pos is Vector3:
			pos = Vector3(pos.x, pos.y, this.position.z)
		this.position = await this.call_watcher(ctx, &"position", pos),
	
	# 设置位置偏移
	# @params: Vector3|Vector2:
	#				位置的偏移值
	#				如果为 Vector2 则 Z 轴保持不变
	&"position/move": func (ctx: LisperContext, this: Mono, offset: Variant) -> void:
		if not offset is Vector3:
			offset = Vector3(offset.x, offset.y, 0)
		var pos := this.position + offset as Vector3
		this.position = await this.call_watcher(ctx, &"position", pos),
	
	
	
	#
	# 信号
	#
	
	# 当位置发生改变时触发
	# @params: void
	&"on_position_mod": Prop.Stack(),
	
	
	
	#
	# Setter
	#
	
	# 当前要移动到的实际位置
	# @type: Vector3
	# 返回 this.position 以阻止移动
	&"on_position": Prop.Stack({
		&"99:position": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Vector3:
			if pos != this.position:
				this.position = pos
				this.emitc(ctx, &"on_position_mod")
				this.setpB(&"_c_render_box", null)
			return pos,
	}),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_init": Prop.puts({
		&"-99:position": func (ctx: LisperContext, this: Mono) -> void:
			var pos = this.getp(&"position")
			if pos is Vector3:
				this.position = pos
			pass,
	}),
	&"on_store": Prop.puts({
		&"-99:position": func (ctx: LisperContext, this: Mono) -> void:
			if this.getp(&"position") != this.position:
				this.setp(&"position", this.position)
			pass,
	}),
	&"on_restore": Prop.puts({
		&"-99:position": func (ctx: LisperContext, this: Mono) -> void:
			var pos = this.getp(&"position")
			if pos is Vector3:
				this.position = pos
			pass,
	}),
}
